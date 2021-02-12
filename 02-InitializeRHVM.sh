#Mount the Hard Drive Containing Files,ISOs,...
WEBIP=192.168.1.111
IDMIP=192.168.1.112
SATIP=192.168.1.113
RHVMIP=192.168.1.120
RHVHIP=192.168.1.152
IDMForwarder=192.168.1.1

Domain=myhost.com
RHVMHost=rhvm
RHVHHost=rhvh01
IDMHost=idm
SatHost=satellite
ORG=MCI

IDMPass=Iahoora@123
SatPass=Iahoora@123
DefaultPass=Iahoora@123

DHCPInt=eth0
DHCPStartIP=192.168.1.50
DHCPEndIP=192.168.1.100
DHCPGW=192.168.1.1
DHCPNetMask=255.255.255.0
##############################################################################
cd /mnt/Mount/Yaml2
cat > /mnt/Mount/Yaml2/.inventory << EOF
[hosts]
${RHVMHost}.${Domain}
${RHVHHost}.${Domain}
EOF

ansible-playbook -i ~/.inventory 01-uploadImage.yml
ansible-playbook -i ~/.inventory 02-uploadISO.yml
#create a vm based on rh8.3
ansible-playbook -i ~/.inventory 03-vmFromImage.yml -e VMName=Template8.3 -e VMMemory=2GiB -e VMCore=1 \
-e ImageName=rhel-8.3-x86_64-kvm.qcow2 -e HostName=template8.3.myhost.com
#create a tempalate based on previous machine
ansible-playbook -i ~/.inventory 04-create-template.yml -e VMName=Template8.3 -e VMTempate=Template8.3
#create a server for idm server baed on previous template
ansible-playbook -i ~/.inventory 05-FromTemplate-WithIP-RH8.yml -e VMName=idm -e VMMemory=4GiB -e VMCore=4  \
-e HostName=idm.myhost.com -e VMTempate=Template8.3 -e VMISO=rhel-8.3-x86_64-dvd.iso -e VMIP=${IDMIP}

#clearing the previous host (in the lab environemnt)
sed -i "/${IDMIP}/d" /root/.ssh/known_hosts
#mount the cdrom on idm
ssh -o StrictHostKeyChecking=no ${IDMIP} "mount -o loop,ro /dev/sr0 /mnt/cdrom"

#install FreeIPA package (ansible-galaxy package seems buggy)
yum localinstall -y /mnt/Mount/Files/ansible-freeipa-0.1.12-6.el8.noarch.rpm
 
mkdir /root/ansible/
cat >  /root/ansible/ansible.cfg << EOF
[defaults]
roles_path   = /usr/share/ansible/roles
library      = /usr/share/ansible/plugins/modules
module_utils = /usr/share/ansible/plugins/module_utils
EOF

cat > /root/ansible/setupIDM.yml << EOF
---
- name: Playbook to configure IPA server
  hosts: ipaserver
  become: true

  roles:
  - role: ipaserver
    state: present
EOF

cat > /root/ansible/.inventory << EOF
[hosts]
${RHVMHost}.${Domain}
${RHVHHost}.${Domain}

[ipaserver]
${IDMIP}
[ipaserver:vars]
ipaserver=${IDMHost}.${Domain}
ipaserver_ip_addresses=${IDMIP}
ipaserver_hostname=${IDMHost}.${Domain}
ipaserver_domain=${Domain}
ipaserver_realm=${Domain^^}
ipaserver_setup_dns=true
ipaserver_auto_forwarders=true
ipadm_password=${IDMPass}
ipaadmin_password=${IDMPass}
ipaserver_setup_dns=true
ipaserver_no_host_dns=true
ipaserver_auto_reverse=true
ipaserver_no_dnssec_validation=true
ipaserver_forwarders=${IDMForwarder}
ipaserver_allow_zone_overlap=true

[ipaclients]
${SATIP}
[ipaclients:vars]
ipaclient_domain=${Domain}
ipaadmin_principal=admin
ipaadmin_password=${IDMPass}
ipasssd_enable_dns_updates=yes
ipaclient_all_ip_addresses=yes
ipaclient_mkhomedir=yes
ipaclient_force_join=yes
[ipaservers]
${IDMHost}.${Domain}
[ipaserver:vars]
ipaadmin_password=${IDMPass}
EOF

cd /root/ansible/

#install IDM on the server
ansible-playbook -i .inventory  setupIDM.yml

ssh -o StrictHostKeyChecking=no ${IDMIP} /bin/bash << EOF
echo ${IDMPass} | kinit admin
ipa dnsconfig-mod --allow-sync-ptr=true
ipa dnszone-mod ${Domain} --allow-sync-ptr=true
ipa sudorule-add AdminRule --hostcat=all  --cmdcat=all --runasusercat=all
ipa sudorule-add-option AdminRule  --sudooption='!authenticate'
ipa sudorule-add-user AdminRule --users=admin
EOF

#setup chronyd so that anybody can sync with it

nmcli con mod ovirtmgmt ipv4.dns ${IDMIP}
nmcli con up ovirtmgmt

#install redhat satellite
####################################################################
cd /mnt/Mount/Yaml2/

#setup a new machine based on rh7.9 for satellite
ansible-playbook -i ~/.inventory 03-vmFromImage.yml -e VMName=Template7.9 -e VMMemory=2GiB \
-e VMCore=1 -e ImageName=rhel-server-7.9-x86_64-kvm.qcow2 -e HostName=template7.9.myhost.com
#create a template from previous machine
ansible-playbook -i ~/.inventory 04-create-template.yml -e VMName=Template7.9 -e VMTempate=Template7.9
#create a machine for satellite based on previous template
ansible-playbook -i ~/.inventory 08-FromTemplate-WithIPDisk-RH7-Satellite.yml -e VMName=satellite \
-e VMMemory=16GiB -e VMCore=6 -e VMDiskSize=100GiB -e HostName=satellite.myhost.com \
-e VMTempate=Template7.9 -e VMISO=rhel-server-7.9-x86_64-dvd.iso -e VMIP=${SATIP} -e VMDNS=${IDMIP}

#clearing the host id (in lab environemnt)
sed -i "/${SATIP}/d" /root/.ssh/known_hosts

#create a partiton on the satellite and mount it as /var
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << 'EOF'
mount -o loop,ro /dev/sr0 /mnt/cdrom
yum -y install lvm2 firewalld
parted -s -a optimal /dev/sdb unit MiB mklabel msdos mkpart primary xfs '0%' '100%' 
pvcreate /dev/sdb1;
vgcreate VG01 /dev/sdb1;
systemctl restart systemd-udevd.service
lvcreate -n var -l 100%FREE VG01;
mkfs.xfs /dev/mapper/VG01-var
mkdir /mnt/temp;
mount /dev/mapper/VG01-var /mnt/temp;
cp -an /var/* /mnt/temp/;
umount /mnt/temp;
export id=$(blkid -s UUID -o value /dev/mapper/VG01-var)
echo "UUID=$id /var xfs defaults 0 0 " >> /etc/fstab
mount -a;
systemctl enable firewalld
systemctl start firewalld
EOF

cd /root/ansible/
cat > /root/ansible/setupIDMClient.yml << EOF
- name: Playbook to configure IPA clients with username/password
  hosts: ipaclients
  become: true

  roles:
  - role: ipaclient
    state: present
EOF
ansible-playbook -i /root/ansible/.inventory  setupIDMClient.yml

######################################################checked
scp -o StrictHostKeyChecking=no   /mnt/Mount/ISOs/satellite-6.8.0-rhel-7-x86_64-dvd.iso ${SATIP}:/var/
ssh -o StrictHostKeyChecking=no ${SATIP} "mount -o loop,ro /var/satellite-6.8.0-rhel-7-x86_64-dvd.iso /mnt/sat"
ssh -o StrictHostKeyChecking=no ${SATIP} "cd /mnt/sat/ &&  ./install_packages"
ssh -o StrictHostKeyChecking=no ${SATIP} satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-cli-foreman-url "https://${SatHost}.${Domain}" \
--foreman-cli-username admin \
--foreman-cli-password "${SatPass}"  --foreman-initial-admin-password "${SatPass}" 
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
if  [  $( firewall-cmd --query-service=RH-Satellite-6) == 'no'  ] 
  then firewall-cmd --permanent --add-service=RH-Satellite-6 
fi
#firewall-cmd --permanent --add-rich-rule "rule family=ipv4 port port=67 protocol=tcp reject"
firewall-cmd --reload

echo -e "${SatPass}" | foreman-prepare-realm admin foremanuser
/usr/bin/cp -f /root/freeipa.keytab /etc/foreman-proxy
chown foreman-proxy:foreman-proxy /etc/foreman-proxy/freeipa.keytab
/usr/bin/cp  -f /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
update-ca-trust enable
update-ca-trust
EOF

ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
satellite-installer  --foreman-proxy-realm true --foreman-proxy-realm-principal foremanuser@${Domain^^} 
EOF

ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
 satellite-installer \
 --foreman-proxy-dhcp true \
 --foreman-proxy-dhcp-interface ${DHCPInt} \
 --foreman-proxy-dhcp-managed true \
 --foreman-proxy-dhcp-range="${DHCPStartIP} ${DHCPEndIP}" \
 --foreman-proxy-dhcp-nameservers ${IDMIP} \
 --foreman-proxy-dhcp-gateway ${DHCPGW} \
 --foreman-proxy-bmc true \
 --foreman-proxy-tftp-servername ${SatHost}.${Domain} \
 --enable-foreman-compute-vmware  --enable-foreman-compute-openstack \
 --enable-foreman-compute-ovirt
EOF

satellite-installer --scenario satellite --foreman-proxy-tftp true --foreman-proxy-tftp-servername satellite.myhost.com
#########################Global config##################
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer settings set --name ansible_ssh_private_key_file --value /var/lib/foreman-proxy/ssh/id_rsa_foreman_proxy 
hammer settings set --name  default_pxe_item_global --value discovery
hammer template build-pxe-default
EOF
#########################ansible config##################
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
sed -i -e 's/^#callback_whitelist = timer, mail/callback_whitelist = foreman/g' /etc/ansible/ansible.cfg
echo "[callback_foreman]" >> /etc/ansible/ansible.cfg
echo "url = https://${SatHost}.${Domain}" >> /etc/ansible/ansible.cfg
echo "ssl_cert = /etc/foreman-proxy/ssl_cert.pem" >> /etc/ansible/ansible.cfg
echo "ssl_key = /etc/foreman-proxy/ssl_key.pem" >> /etc/ansible/ansible.cfg
echo "verify_certs = /etc/foreman-proxy/ssl_ca.pem" >> /etc/ansible/ansible.cfg
EOF
#################################################################################
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer auth-source ldap create --name ${IDMHost}.${Domain} --host ${IDMHost}.${Domain} --server-type free_ipa \
--account admin --account-password ${IDMPass} --base-dn $(echo ${Domain} | awk -F. '{print "dc="$1",dc="$2}')  --onthefly-register true \
--attr-login uid  --attr-firstname givenName --attr-lastname sn --attr-mail mail
hammer realm create --name ${Domain^^} --realm-type "Red Hat Identity Management" --realm-proxy-id 1 --organization-id 1
EOF
#########################network config##################

SubnetName=$(echo ${DHCPStartIP} | awk -F. '{print "subnet"$3}')
IPRange=$(echo ${DHCPStartIP} | awk -F. '{print $1"."$2"."$3}')
Network=${IPRange}.0
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer subnet create --name ${SubnetName} --network ${Network} --mask ${DHCPNetMask} --gateway ${DHCPGW}  \
--dns-primary ${IDMIP}  --tftp ${SatHost}.${Domain} --discovery-id 1 --httpboot-id 1 --domains ${Domain} --organization-id 1 \
--ipam DHCP --boot-mode DHCP --from ${DHCPStartIP} --to ${DHCPEndIP} --dhcp ${SatHost}.${Domain} 
EOF

#################################################################################
ssh -o StrictHostKeyChecking=no ${IDMIP} /bin/bash << EOF
echo "${SatPass}" | kinit admin; ipa dnsrecord-add ${Domain}. ${RHVHHost} --a-ip-address=${RHVHIP}  --a-create-reverse 
EOF
mkdir /mnt/cdrom
mount -o loop,ro /mnt/Mount/ISOs/rhel-8.3-x86_64-dvd.iso /mnt/cdrom
cat <<EOD > /etc/yum.repos.d/cd.repo
[AppStrem]
name=appstrem
baseurl=file:///mnt/cdrom/AppStream
gpgcheck=0

[BaseOS]
name=baseos
baseurl=file:///mnt/cdrom/BaseOS/
gpgcheck=0
EOD

yum install -y httpd
systemctl start httpd
firewall-cmd --add-service=http
mkdir /var/www/html/RHEL
restorecon -Rv /var/www/html/RHEL
mount -o ro UUID=79ad740b-6cd9-44d0-941a-39fb4939341a /mnt/Mount
ln -s /mnt/Mount /var/www/html/RHEL
#copy manifest
scp -o StrictHostKeyChecking=no /mnt/Mount/Files/manifest_satellite.zip ${SATIP}:~/
ssh -o StrictHostKeyChecking=no ${SATIP} hammer subscription upload --file ~/manifest_satellite.zip --organization-id 1 --repository-url http://${RHVHHost}.${Domain}/RHEL

ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer product create --organization-id 1 --name MyProducts
hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ceph Storage MON 4 for RHEL 8 x86_64 (RPMs)" --url http://rhvh01.myhost.com/RHEL/content/dist/layered/rhel8/x86_64/rhceph-mon/4/os/
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Ceph Storage MON 4 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ceph Storage OSD 4 for RHEL 8 x86_64 (RPMs)" --url http://rhvh01.myhost.com/RHEL/content/dist/layered/rhel8/x86_64/rhceph-osd/4/os
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Ceph Storage OSD 4 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)" --url http://rhvh01.myhost.com/RHEL/content/dist/layered/rhel8/x86_64/rhceph-tools/4/os/
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8" --url http://rhvh01.myhost.com/RHEL/content/dist/rhel8/8/x86_64/baseos/os/
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8" --url http://rhvh01.myhost.com/RHEL/content/dist/rhel8/8/x86_64/appstream/os/
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)" --url http://rhvh01.myhost.com/RHEL/content/dist/layered/rhel8/x86_64/ansible/2.9/os/
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Satellite Tools 6.8 for RHEL 8 x86_64 RPMs" --url http://rhvh01.myhost.com/RHEL/content/dist/layered/rhel8/x86_64/sat-tools/6.8/os
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Satellite Tools 6.8 for RHEL 8 x86_64 RPMs" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat Enterprise Linux High Availability for x86_64" --url http://rhvh01.myhost.com/RHEL/content/dist/rhel8/8/x86_64/highavailability/os/
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat Enterprise Linux High Availability for x86_64" --async

hammer repository create --product MyProducts --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 --name "Red Hat OpenStack Platform 16 Tools for RHEL 8 x86_64 (RPMs)" --url http://rhvh01.myhost.com/RHEL/content/dist/layered/rhel8/x86_64/openstack-tools/16/os/
hammer repository sync --organization-id 1 --product MyProducts --name "Red Hat OpenStack Platform 16 Tools for RHEL 8 x86_64 (RPMs)" --async

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
EOF
#####################################################################################################
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer content-view create --name contentview01 --label contentview01 --organization-id 1 
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Ceph Storage MON 4 for RHEL 8 x86_64 (RPMs)"
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Ceph Storage OSD 4 for RHEL 8 x86_64 (RPMs)"
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)"
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8"
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8"
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart 8.3"
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - AppStream Kickstart 8.3"
hammer content-view add-repository --name contentview01  --organization-id 1 --repository "Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)"

hammer content-view publish --name contentview01 --organization-id 1 #--async
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev

hammer activation-key create --name mykey01 --organization-id 1 --lifecycle-environment Library --content-view contentview01
 hammer activation-key update --name mykey01 --auto-attach false --organization-id 1
id=$( hammer activation-key add-subscription --name mykey01 --subscription-id 24  --organization-id 1)
hammer activation-key add-subscription --name mykey01 --subscription-id ${id} --organization-id 1
EOF
#####################################################################################################
#########################hostgroup config##################  OK 
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer hostgroup create --name hostgroup01 --lifecycle-environment Library   \
--architecture x86_64 --root-password ${DefaultPass} --organization-id 1 \
--operatingsystem "RedHat 8.3"  --partition-table "Kickstart default"  \
--pxe-loader 'PXELinux BIOS'   --domain ${Domain}  --subnet ${SubnetName}    \
--content-view contentview01 --content-source ${SatHost}.${Domain} --realm ${Domain^^}
EOF

#########################hostgroup parameter##################   OK
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_server --parameter-type string --value ${IDMHost}.${Domain}
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_domain --parameter-type string --value ${Domain^^}
hammer hostgroup set-parameter --hostgroup hostgroup01  --name package_upgrade --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name use-ntp --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name time-zone --parameter-type string --value Asia/Tehran
hammer hostgroup set-parameter --hostgroup hostgroup01  --name ntp-server --parameter-type string --value ${IDMIP}
pubkey=$(curl -k https://${SatHost}.${Domain}:9090/ssh/pubkey)
hammer hostgroup set-parameter --hostgroup hostgroup01  --name remote_execution_ssh_keys  --parameter-type array --value "[${pubkey}]"
hammer hostgroup set-parameter --hostgroup hostgroup01  --name redhat_install_agent --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name subscription_manager --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name redhat_install_host_tools --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name atomic --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name subscription_manager_certpkg_url --parameter-type string --value https://${SatHost}.${Domain}/pub/katello-ca-consumer-latest.noarch.rpm
hammer hostgroup set-parameter --hostgroup hostgroup01  --name kt_activation_keys --parameter-type string --value mykey01
hammer hostgroup set-parameter --hostgroup hostgroup01  --name realm.realm_type --parameter-type string --value FreeIPA
hammer hostgroup set-parameter --hostgroup hostgroup01  --name enable-epel --parameter-type boolean --value false
EOF

###########################################################################
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
cat >  /tmp/packages << EOF2
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
EOF2
hammer template create --name "Kickstart default custom packages" --type snippet --file /tmp/packages --organization-id 1
cat >  /tmp/post << EOF2
sed -i 's/crashkernel=auto//g' /etc/default/grub
grub2-mkconfig > /boot/grub2/grub.cfg
systemctl disable kdump.service
systemctl mask kdump.service

ls -d /etc/yum.repos.d/* | grep -v redhat.repo |xargs -I % mv % %.bkp
EOF2
hammer template create --name "Kickstart default custom post" --type snippet --file /tmp/post --organization-id 1

cat > /tmp/partition <<EOF2
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
EOF2

hammer partition-table create --file /tmp/partition --name "Kickstart default single disk" --operatingsystems "RedHat 8.3" \
--organization-id 1 --os-family Redhat --location "Default Location" --hostgroup-titles hostgroup01

EOF
hammer host create --name myhost01 --hostgroup hostgroup01 --content-source ${SatHost}.${Domain}   \
--partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"   --organization-id 1  --location "Default Location" \
--interface mac=00:0C:29:2B:7B:C8  --build true --enabled true --managed true \
--kickstart-repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart 8.3" \
--lifecycle-environment "Library" --content-view "contentview01" 



