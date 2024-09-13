#Copy HardDisk contents required for satellite to /var/Mount
IDMIP=172.17.58.97
SATIP=172.16.49.97
IDMForwarder=172.18.9.3

Domain=idm.mci.ir
RHVHHost=rhvh01
IDMHost=ipa01
SatHost=satellite
ORG=MCI

IDMPass=Iahoora@123
SatPass=Iahoora@123
DefaultPass=Iahoora@123

###############################Create Debug key###############################
curl -s -H "Accept:application/json" -k -u admin:${SatPass} https://${satellite}.${Domain}/katello/api/v2/organizations/1/download_debug_certificate \
|  awk '{print > "cert" (1+n) ".pem"} /-----END RSA PRIVATE KEY-----/ {n++}'
hammer content-credentials create --organization-id 1  --name DebugKey --key cert1.pem --content-type gpg_key
hammer content-credentials create --organization-id 1  --name DebugCert --key cert2.pem --content-type cert
#############################################################################################

##############################################
#hostnamectl set-hostname ${SatHost}.${Domain}
#nmcli con mod ens192 ipv4.dns ${IDMIP} ipv4.dns-search ${Domain}
#nmcli con up ens192
#ln -s /var/Mount/ /mnt/Mount
#ls | grep -v Mount | xargs rm -rf  {}
 
mkdir /mnt/cdrom
mount -o loop,ro /var/Mount/ISOs/rhel-server-7.9-x86_64-dvd.iso /mnt/cdrom/

cat > /etc/yum.repos.d/cd.repo << EOF
[cdrom]
name=cdrom-base
baseurl=file:///mnt/cdrom
gpgcheck=no
EOF

mkdir /mnt/sat
mount -o loop,ro /var/Mount/ISOs/satellite-6.8.0-rhel-7-x86_64-dvd.iso /mnt/sat

yum install -y ipa-client 
ipa-client-install --principal admin --password ${IDMPass}  --unattended  \
--domain ${Domain} --enable-dns-updates --all-ip-addresses --mkhomedir \
--automount-location=default  --realm ${Domain^^} --force-join

#ReverseIP=$(echo ${SATIP} | awk -F. '{print $3"."$2"."$1".in-addr.arpa."}')

#ipa dnsrecord-add ${Domain}. $(hostname -f). --a-ip-address=${SATIP}  --a-create-reverse 
######################################################checked
echo "Iahoora@123" | kinit admin
ipa service-add HTTP/$(hostname -f)
ipa-getcert request -K HTTP/$(hostname) -D $(hostname) -k /etc/pki/tls/private/$(hostname).key -f /etc/pki/tls/certs/$(hostname).crt

#katello-certs-check -t satellite -c /etc/pki/tls/certs/$(hostname).crt -k /etc/pki/tls/private/$(hostname).key -b /etc/ipa/ca.crt

cd /mnt/sat/ &&  time ./install_packages
#reboot may be required after this part (or unmount!)
time satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-cli-foreman-url "https://${SatHost}.${Domain}" \
--foreman-cli-username admin \
--foreman-cli-password "${SatPass}"  --foreman-initial-admin-password "${SatPass}" \
--certs-server-cert /etc/pki/tls/certs/$(hostname).crt --certs-server-key /etc/pki/tls/private/$(hostname).key \
--certs-server-ca-cert /etc/ipa/ca.crt 

if  [  $( firewall-cmd --query-service=RH-Satellite-6) == 'no'  ] 
  then firewall-cmd --permanent --add-service=RH-Satellite-6 
fi
#firewall-cmd --permanent --add-rich-rule "rule family=ipv4 port port=67 protocol=tcp reject"
firewall-cmd --reload

cd ~
echo -e "${SatPass}" | foreman-prepare-realm admin foremanuser
/usr/bin/cp -f /root/freeipa.keytab /etc/foreman-proxy
chown foreman-proxy:foreman-proxy /etc/foreman-proxy/freeipa.keytab
/usr/bin/cp  -f /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
update-ca-trust enable
update-ca-trust

satellite-installer  --foreman-proxy-realm true --foreman-proxy-realm-principal foremanuser@${Domain^^} 
satellite-installer --scenario satellite --foreman-proxy-tftp true --foreman-proxy-tftp-servername $(hostname)

hammer settings set --name ansible_ssh_private_key_file --value /var/lib/foreman-proxy/ssh/id_rsa_foreman_proxy 
hammer settings set --name  default_pxe_item_global --value discovery
hammer template build-pxe-default

#########################ansible config##################
sed -i -e 's/^#callback_whitelist = timer, mail/callback_whitelist = foreman/g' /etc/ansible/ansible.cfg
echo "[callback_foreman]" >> /etc/ansible/ansible.cfg
echo "url = https://${SatHost}.${Domain}" >> /etc/ansible/ansible.cfg
echo "ssl_cert = /etc/foreman-proxy/ssl_cert.pem" >> /etc/ansible/ansible.cfg
echo "ssl_key = /etc/foreman-proxy/ssl_key.pem" >> /etc/ansible/ansible.cfg
echo "verify_certs = /etc/foreman-proxy/ssl_ca.pem" >> /etc/ansible/ansible.cfg
#################################################################################
#can also configure with ldaps
array=(${Domain//./ })
for i in "${array[@]}" ; do out+="dc=$i," ; done
output=${out::-1}
hammer auth-source ldap create --name ${IDMHost}.${Domain} --host ${IDMHost}.${Domain} --server-type free_ipa \
--account admin --account-password ${IDMPass} --base-dn ${output}  --onthefly-register true \
--attr-login uid  --attr-firstname givenName --attr-lastname sn --attr-mail mail
hammer realm create --name ${Domain^^} --realm-type "Red Hat Identity Management" --realm-proxy-id 1 --organization-id 1
#########################network config##################

#SubnetName=$(echo ${DHCPStartIP} | awk -F. '{print "subnet"$3}')
#IPRange=$(echo ${DHCPStartIP} | awk -F. '{print $1"."$2"."$3}')
#Network=${IPRange}.0
#ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
#hammer subnet create --name ${SubnetName} --network ${Network} --mask ${DHCPNetMask} --gateway ${DHCPGW}  \
#--dns-primary ${IDMIP}  --tftp ${SatHost}.${Domain} --discovery-id 1 --httpboot-id 1 --domains ${Domain} --organization-id 1 \
#--ipam DHCP --boot-mode DHCP --from ${DHCPStartIP} --to ${DHCPEndIP} --dhcp ${SatHost}.${Domain} 

#################################################################################
#semanage fcontext -a -t httpd_sys_content_t '/var/Mount(/.*)?'
#restorecon -Rv /var/Mount/
ln -s /var/Mount/ /var/www/html/pub/RHEL

#copy manifest
hammer subscription upload --file /var/Mount/Files/manifest_satellite.zip --organization-id 1 --repository-url http://${SatHost}.${Domain}/pub/RHEL

hammer product create --organization-id 1 --name RH
hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ceph Storage MON 4 for RHEL 8 x86_64 (RPMs)" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/layered/rhel8/x86_64/rhceph-mon/4/os/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Ceph Storage MON 4 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ceph Storage OSD 4 for RHEL 8 x86_64 (RPMs)" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/layered/rhel8/x86_64/rhceph-osd/4/os
hammer repository sync --organization-id 1 --product RH --name "Red Hat Ceph Storage OSD 4 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/layered/rhel8/x86_64/rhceph-tools/4/os/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel8/8/x86_64/baseos/os/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel8/8/x86_64/appstream/os/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/layered/rhel8/x86_64/ansible/2.9/os/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Satellite Tools 6.8 for RHEL 8 x86_64 RPMs" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/layered/rhel8/x86_64/sat-tools/6.8/os
hammer repository sync --organization-id 1 --product RH --name "Red Hat Satellite Tools 6.8 for RHEL 8 x86_64 RPMs" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Enterprise Linux High Availability for x86_64" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel8/8/x86_64/highavailability/os/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Enterprise Linux High Availability for x86_64" --async

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat OpenStack Platform 16 Tools for RHEL 8 x86_64 (RPMs)" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/layered/rhel8/x86_64/openstack-tools/16/os/
hammer repository sync --organization-id 1 --product RH --name "Red Hat OpenStack Platform 16 Tools for RHEL 8 x86_64 (RPMs)" --async


hammer product create --organization-id 1 --name RH7

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name \
"Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/os
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name \
"Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/rh-common/os
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name \
"Red Hat Enterprise Linux 7 Server - Extras RPMs x86_64" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/extras/os
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Enterprise Linux 7 Server - Extras RPMs x86_64" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name \
"Red Hat Enterprise Linux High Availability for RHEL 7 Server RPMs x86_64 7Server" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/highavailability/os
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Enterprise Linux High Availability for RHEL 7 Server RPMs x86_64 7Server" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name \
"Red Hat Ansible Engine 2.9 RPMs for Red Hat Enterprise Linux 7 Server x86_64" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/ansible/2.9/os
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Ansible Engine 2.9 RPMs for Red Hat Enterprise Linux 7 Server x86_64" --async

hammer repository-set enable --organization-id 1 --basearch x86_64 --releasever 8.3 --id 7421
hammer repository-set enable --organization-id 1 --basearch x86_64 --releasever 8.3 --id 7446

id=$(hammer --output csv --no-headers repository list --name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart 8.3" | awk -F, '{print $1}')
hammer repository update --organization-id 1 --mirror-on-sync false --download-policy immediate --id $id
hammer repository synchronize --organization-id 1 --id $id --async

id=$(hammer --output csv --no-headers repository list --name "Red Hat Enterprise Linux 8 for x86_64 - AppStream Kickstart 8.3" | awk -F, '{print $1}')
hammer repository update --organization-id 1 --mirror-on-sync false --download-policy immediate --id $id
hammer repository synchronize --organization-id 1 --id $id --async

hammer lifecycle-environment create  --description "dev"  --name dev  --label dev --organization-id 1 --prior Library
hammer lifecycle-environment create  --description "qa"  --name qa  --label qa --organization-id 1 --prior dev
hammer lifecycle-environment create  --description "prod"  --name prod  --label prod --organization-id 1 --prior qa

#####################################################################################################
hammer content-view create --name vrh7 --label vrh7 --organization-id 1 
hammer content-view add-repository --name  vrh7  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server"
hammer content-view add-repository --name  vrh7  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server"
hammer content-view add-repository --name  vrh7  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux 7 Server - Extras RPMs x86_64"
hammer content-view add-repository --name  vrh7  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux High Availability for RHEL 7 Server RPMs x86_64 7Server"
hammer content-view add-repository --name  vrh7  --product RH7 --organization-id 1 --repository "Red Hat Ansible Engine 2.9 RPMs for Red Hat Enterprise Linux 7 Server x86_64"

hammer content-view publish --name vrh7 --organization-id 1 --async
hammer activation-key create --name krh7 --organization-id 1 --lifecycle-environment Library --content-view vrh7
hammer activation-key update --name krh7 --auto-attach false --organization-id 1
subsID=$(hammer --output csv --no-headers  subscription list | grep ",RH7," | awk -F, '{print $1}')
hammer activation-key add-subscription --name krh7 --subscription-id ${subsID}  --organization-id 1

#####################################################################################################
hammer content-view create --name vceph4 --label vceph4 --organization-id 1 
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Ceph Storage MON 4 for RHEL 8 x86_64 (RPMs)"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Ceph Storage OSD 4 for RHEL 8 x86_64 (RPMs)"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart 8.3"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - AppStream Kickstart 8.3"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)"

hammer content-view publish --name vceph4 --organization-id 1 --async
#hammer content-view  version promote --organization-id 1  --content-view vceph4 --to-lifecycle-environment dev

hammer activation-key create --name kceph04 --organization-id 1 --lifecycle-environment Library --content-view vceph4
hammer activation-key update --name kceph04 --auto-attach false --organization-id 1
subsID=$(hammer --output csv --no-headers  subscription list | grep ",RH," | awk -F, '{print $1}')
#id=$( hammer activation-key add-subscription --name kceph04 --subscription-id ${subsID}  --organization-id 1)
hammer activation-key add-subscription --name kceph04 --subscription-id ${subsID}  --organization-id 1
#hammer activation-key add-subscription --name kceph04 --subscription-id ${id} --organization-id 1

#####################################################################################################

###########################################################################
cat >  /tmp/packages << EOF
subscription-manager
ipa-client
bash-completion
tuned
lsof
nmap
tmux
tcpdump
telnet
unzip
vim
yum-utils
bind-utils
sysstat
xorg-x11-xauth 
dbus-x11
EOF
hammer template create --name "Kickstart default custom packages" --type snippet --file /tmp/packages --organization-id 1

cat >  /tmp/post << EOF
sed -i 's/crashkernel=auto//g' /etc/default/grub
grub2-mkconfig > /boot/grub2/grub.cfg
systemctl disable kdump.service
systemctl mask kdump.service
update-ca-trust
EOF
hammer template create --name "Kickstart default custom post" --type snippet --file /tmp/post --organization-id 1

cat > /tmp/partition <<EOF
<%#
kind: ptable
name: Kickstart default
model: Ptable
oses:
- CentOS
- Fedora
- RedHat
%>
zerombr
clearpart --all --initlabel
ignoredisk --only-use=sda
autopart <%= host_param('autopart_options') %>
EOF
hammer partition-table create --file /tmp/partition --name "Kickstart default single disk" --operatingsystems "RedHat 8.3" \
--organization-id 1 --os-family Redhat --location "Default Location" 
#--hostgroup-titles HGCeph4

#because of an error in kickstart default to bond the physical ports
hammer template dump --name "Kickstart default" > /tmp/ks-default
cat > /tmp/ks-default-bond << EOF
--- /tmp/ks-default     2021-04-17 19:11:14.518600180 -0400
+++ /tmp/ks-default-bond        2021-04-17 19:11:48.084600180 -0400
@@ -143,8 +143,9 @@

   # bond
   if iface.bond? && rhel_compatible && os_major >= 6
-    network_options.push("--bondslaves=#{iface.attached_devices_identifiers}")
-    network_options.push("--bondopts=mode=#{iface.mode};#{iface.bond_options.tr(' ', ';')}")
+    bond_slaves = iface.attached_devices_identifiers.join(',')
+    network_options.push("--bondslaves=#{bond_slaves}")
+    network_options.push("--bondopts=mode=#{iface.mode};#{iface.bond_options.tr('', ';')}")
   end

   # VLAN (only on physical is recognized)
EOF
patch /tmp/ks-default /tmp/ks-default-bond
hammer template create --file /tmp/ks-default --name "Kickstart default-bond" --type "provision" --organization-id 1
hammer template add-operatingsystem --name "Kickstart default-bond" --operatingsystem "RedHat 8.3"
hammer template remove-operatingsystem --name "Kickstart default" --operatingsystem "RedHat 8.3"
osid=$(hammer --output csv --no-headers  os list | grep ",RedHat 8.3," | awk -F, '{print $1}')
tempid=$(hammer --output csv --no-headers  template list | grep ",Kickstart default-bond," | awk -F, '{print $1}')
hammer os set-default-template --id ${osid} --provisioning-template-id ${tempid}
 
hammer template create --name "Kickstart default-bond custom packages" --type snippet --file /tmp/packages --organization-id 1
hammer template create --name "Kickstart default-bond custom post" --type snippet --file /tmp/post --organization-id 1
hammer partition-table create --file /tmp/partition --name "Kickstart default-bond single disk" --operatingsystems "RedHat 8.3" \
--organization-id 1 --os-family Redhat --location "Default Location" 
#--hostgroup-titles HGCeph4

#########################hostgroup config##################  OK 

hammer hostgroup create --name HGBase --lifecycle-environment Library   \
--architecture x86_64 --root-password ${DefaultPass} --organization-id 1 \
--partition-table "Kickstart default single disk"  \
--domain ${Domain} --content-source ${SatHost}.${Domain} --realm ${Domain^^} 

hammer hostgroup set-parameter --hostgroup HGBase --name freeipa_server --parameter-type string --value ${IDMHost}.${Domain}
hammer hostgroup set-parameter --hostgroup HGBase --name freeipa_domain --parameter-type string --value ${Domain^^}
hammer hostgroup set-parameter --hostgroup HGBase  --name package_upgrade --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup HGBase  --name use-ntp --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup HGBase  --name time-zone --parameter-type string --value Asia/Tehran
hammer hostgroup set-parameter --hostgroup HGBase  --name ntp-server --parameter-type string --value ${IDMIP}
pubkey=$(curl -k https://${SatHost}.${Domain}:9090/ssh/pubkey)
hammer hostgroup set-parameter --hostgroup HGBase  --name remote_execution_ssh_keys  --parameter-type array --value "[${pubkey}]"
hammer hostgroup set-parameter --hostgroup HGBase  --name redhat_install_agent --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup HGBase  --name subscription_manager --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup HGBase  --name redhat_install_host_tools --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup HGBase  --name atomic --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup HGBase  --name subscription_manager_certpkg_url --parameter-type string --value http://${SatHost}.${Domain}/pub/katello-ca-consumer-latest.noarch.rpm
hammer hostgroup set-parameter --hostgroup HGBase  --name realm.realm_type --parameter-type string --value FreeIPA
hammer hostgroup set-parameter --hostgroup HGBase  --name enable-epel --parameter-type boolean --value false


hammer hostgroup create --name HGBareMetal --parent HGBase --pxe-loader 'Grub2 UEFI'   
hammer hostgroup create --name HGVirtual --parent HGBase --pxe-loader 'PXELinux BIOS'   

hammer hostgroup create --name HGPCeph4 --parent HGBareMetal --operatingsystem "RedHat 8.3" --content-view vceph4 --organization-id 1
hammer hostgroup set-parameter --hostgroup HGPCeph4  --name kt_activation_keys --parameter-type string --value kceph04

#hammer host create --name myhost01 --hostgroup HGCeph4 --content-source ${SatHost}.${Domain}   \
#--partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"   --organization-id 1  --location "Default Location" \
#--interface mac=00:0C:29:2B:7B:C8  --build true --enabled true --managed true \
#--kickstart-repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart 8.3" \
#--lifecycle-environment "Library" --content-view "vceph4" 



