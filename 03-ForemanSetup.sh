source ~/sitesetup/variables.sh
domain=$ForemanHOSTNAME
domainname=$IDMDomain
pass=$ForemanPass

gw=$ForemanGW
dns=$IDMIP
interface=$(nmcli dev | grep connected | awk  '{print $1}')
subnetname=$(echo ${ForemanIP} | awk -F. '{print "subnet"$3}')
IPRange=$(echo ${ForemanIP} | awk -F. '{print $1"."$2"."$3}')
startip=$IPRange.50
endip=$IPRange.100
network=$IPRange.0
netmask=255.255.255.0

idmhost=$IDMHOSTNAME
idmpass=$IDMPass
idmdn=$(echo $IDMDomain | awk -F. '{print "dc="$1",dc="$2}')
idmdn="dc=myhost,dc=com"
idmrealm=$IDMRealm

#default Values
idmuser=admin
newsyspass=Iahoora@123
OS=CentOS
major=7
minor=8.2003
################################################################installation#########################################################################
hammer lifecycle-environment create  --description "dev"  --name dev  --label dev --organization-id 1 --prior Library
hammer lifecycle-environment create  --description "qa"  --name qa  --label qa --organization-id 1 --prior dev
hammer lifecycle-environment create  --description "prod"  --name prod  --label prod --organization-id 1 --prior qa
#foreman-maintain service restart
################################################################basic media#########################################################################
#########################medium config##################OK

mount -o ro /dev/cdrom /mnt/cdrom
mkdir -p /var/www/html/pub/media/
/usr/bin/cp -rf /mnt/cdrom /var/www/html/pub/media
mv /var/www/html/pub/media/cdrom /var/www/html/pub/media/$OS$major.$minor
curl -o /var/www/html/pub/media/$OS$major.$minor/images/boot.iso http://mirror.centos.org/centos/7/os/x86_64/images/boot.iso
restorecon -Rv /var/www/html/pub/media/$OS$major.$minor
hammer product create --name $OS --label $OS --organization-id 1
hammer medium create --name $OS$major.$minor --os-family Redhat --path http://$domain/pub/media/$OS$major.$minor --organization-id 1
#########################repository config##################OK
hammer repository   create  --name $OS$major.$minor    --content-type yum  --organization-id 1  \
--product $OS --url http://$domain/pub/media/$OS$major.$minor --download-policy immediate --mirror-on-sync false
hammer repository synchronize  --organization-id 1 --product $OS  --name $OS$major.$minor #--async

hammer repository   create  --name foreman-client  --content-type yum  --organization-id 1 \
--product $OS --url https://yum.theforeman.org/client/2.1/el7/x86_64/ --download-policy immediate --mirror-on-sync false
hammer repository synchronize  --organization-id 1 --product $OS  --name foreman-client #--async
#########################os config##################Ok-SoSO (why PXElinux?)
hammer os create --architectures x86_64 --name $OS --media $OS$major.$minor --partition-tables "Kickstart default" --major $major --minor $minor \
--provisioning-templates "PXELinux global default" --family "Redhat"
hammer os update --title "$OS $major.$minor" --media $OS$major.$minor
hammer template add-operatingsystem --name "PXELinux global default" --operatingsystem "$OS $major.$minor"
 
#########################contentview config##################   OK
hammer content-view create --name contentview01 --label contentview01 --organization-id 1 
hammer content-view add-repository --name contentview01 --repository $OS$major.$minor --organization-id 1 
hammer content-view add-repository --name contentview01 --repository foreman-client --organization-id 1
hammer content-view publish --name contentview01 --organization-id 1 #--async
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev

hammer activation-key create --name mykey01 --organization-id 1 --lifecycle-environment Library --content-view contentview01
hammer activation-key add-subscription --name mykey01 --subscription $OS --organization-id 1

#########################ansible config##################   OK
ansible-galaxy install hamidreza2000us.splunk_forwarder  -p /usr/share/ansible/roles/
hammer ansible roles import --proxy-id 1 --role-names hamidreza2000us.splunk_forwarder
ansible-galaxy install hamidreza2000us.chrony -p /usr/share/ansible/roles/
hammer ansible roles import --role-names hamidreza2000us.chrony --proxy-id 1
ansible-galaxy install hamidreza2000us.motd -p /usr/share/ansible/roles/
hammer ansible roles import --role-names hamidreza2000us.motd --proxy-id 1
hammer ansible variables import --proxy-id 1
hammer ansible variables update --override true  --variable ntpserver --variable-type string  \
 --default-value "$idmhost" --ansible-role  hamidreza2000us.chrony  --hidden-value false  --name ntpserver
#########################hostgroup config##################  OK 
hammer hostgroup create --name hostgroup01 --lifecycle-environment Library   \
--architecture x86_64 --root-pass $newsyspass --organization-id 1 \
--operatingsystem "$OS $major.$minor" --medium $OS$major.$minor --partition-table "Kickstart default"  \
--pxe-loader 'PXELinux BIOS'   --domain $domainname  --subnet $subnetname    \
--content-view contentview01 --content-source $domain --realm $idmrealm 
#########################hostgroup parameter##################   OK
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_server --parameter-type string --value $idmhost
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_domain --parameter-type string --value $idmrealm
#hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles rhel-system-roles.timesync 
#hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles "hamidreza2000us.chrony,hamidreza2000us.motd"
hammer hostgroup set-parameter --hostgroup hostgroup01  --name package_upgrade --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name use-ntp --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name time-zone --parameter-type string --value Asia/Tehran
hammer hostgroup set-parameter --hostgroup hostgroup01  --name ntp-server --parameter-type string --value $dns

pubkey=$(curl -k https://$domain:9090/ssh/pubkey)
hammer hostgroup set-parameter --hostgroup hostgroup01  --name remote_execution_ssh_keys  --parameter-type array --value "[$pubkey]"
hammer hostgroup set-parameter --hostgroup hostgroup01  --name redhat_install_agent --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name subscription_manager --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name redhat_install_host_tools --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name atomic --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name subscription_manager_certpkg_url --parameter-type string --value https://$domain/pub/katello-ca-consumer-latest.noarch.rpm
hammer hostgroup set-parameter --hostgroup hostgroup01  --name kt_activation_keys --parameter-type string --value mykey01
hammer hostgroup set-parameter --hostgroup hostgroup01  --name freeipa_server --parameter-type string --value $idmhost
hammer hostgroup set-parameter --hostgroup hostgroup01  --name freeipa_domain --parameter-type string --value $idmrealm
hammer hostgroup set-parameter --hostgroup hostgroup01  --name realm.realm_type --parameter-type string --value FreeIPA
hammer hostgroup set-parameter --hostgroup hostgroup01  --name enable-epel --parameter-type boolean --value false
######################################################################################################


#########################scap config################## Ok (change scap profile to centos)
#ansible-galaxy install giovtorres.postfix-null-client -p /usr/share/ansible/roles/
ansible-galaxy  install theforeman.foreman_scap_client -p /usr/share/ansible/roles/
foreman-rake foreman_openscap:bulk_upload:default
hammer ansible roles import --role-names theforeman.foreman_scap_client --proxy-id 1
hammer ansible variables import --proxy-id 1
hammer policy create --organization-id 1 --period monthly --day-of-month 1 --deploy-by ansible --hostgroups hostgroup01 --name policy01  --scap-content-profile-id 5  --scap-content-id 2
hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles "hamidreza2000us.chrony,hamidreza2000us.motd,hamidreza2000us.splunk_forwarder"
hammer ansible variables update --override true  --variable foreman_scap_client_server --variable-type string \
--default-value "$domain" --ansible-role  theforeman.foreman_scap_client  --hidden-value false  --name foreman_scap_client_server
###############################################Templates###############################################OK (with some fixes)
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
splunkforwarder
EOF
hammer template create --name "Kickstart default custom packages" --type snippet --file /tmp/packages --organization-id 1
hammer template create --name "Kickstart scap custom packages" --type snippet --file /tmp/packages --organization-id 1

cat >  /tmp/post << EOF
sed -i 's/crashkernel=auto//g' /etc/default/grub
grub2-mkconfig > /boot/grub2/grub.cfg
systemctl disable kdump.service
systemctl mask kdump.service

ls -d /etc/yum.repos.d/* | grep -v redhat.repo |xargs -I % mv % %.bkp
EOF
hammer template create --name "Kickstart default custom post" --type snippet --file /tmp/post --organization-id 1
hammer template create --name "Kickstart scap custom post" --type snippet --file /tmp/post --organization-id 1

#because of a bug in satellite 6.8 with bonded interfaces
#########################################################
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
hammer template add-operatingsystem --name "Kickstart default-bond" --operatingsystem "$OS $major.$minor"

#########################################################
sed  -i '/^skipx.*/a \\n%addon org_fedora_oscap\ncontent-type = scap-security-guide\nprofile = pci-dss\n%end' /tmp/ks-default
hammer template create --file /tmp/ks-default --name "Kickstart scap" --type "provision" --organization-id 1
hammer template add-operatingsystem --name "Kickstart scap" --operatingsystem "$OS $major.$minor"
#osid=$(hammer --csv os list | grep "$OS $major.$minor," | awk -F, {'print $1'})
#SATID=$(hammer --csv template list  | grep "provision" | grep ",Kickstart scap," | cut -d, -f1)
#hammer os set-default-template --id $osid --provisioning-template-id $SATID

hammer host create --name myhost01 --hostgroup hostgroup01 --content-source $domain \
 --medium $OS$major.$minor --partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"  \
 --organization-id 1  --location "Default Location" --interface mac=00:0C:29:2B:7B:C8 \
 --build true --enabled true --managed true
#--openscap-proxy-id 1

###############################Create Debug key###############################
curl -s -H "Accept:application/json" -k -u admin:${pass} https://${domain}/katello/api/v2/organizations/1/download_debug_certificate \
|  awk '{print > "cert" (1+n) ".pem"} /-----END RSA PRIVATE KEY-----/ {n++}'
hammer content-credentials create --organization-id 1  --name DebugKey --key cert1.pem --content-type gpg_key
hammer content-credentials create --organization-id 1  --name DebugCert --key cert2.pem --content-type cert
#############################################################################################

###############################
#curl --insecure --output katello-ca-consumer-latest.noarch.rpm  https://$domain/pub/katello-ca-consumer-latest.noarch.rpm
#yum localinstall -y katello-ca-consumer-latest.noarch.rpm
#subscription-manager register --org="Default_Organization" --activationkey=mykey01
#yum -y install katello-host-tools
#yum -y install katello-host-tools-tracer
#yum -y install katello-agent

# ansible-galaxy install robertdebock.auditd  -p /usr/share/ansible/roles/
# ansible-galaxy install robertdebock.rsyslog  -p /usr/share/ansible/roles/

###############################upload splunk packages###############################
mkdir -p /var/www/html/pub/packages/Splunk
curl -o /var/www/html/pub/packages/Splunk/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm \
https://download.splunk.com/products/splunk/releases/8.1.0/linux/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

curl -o /var/www/html/pub/packages/Splunk/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm \
https://download.splunk.com/products/universalforwarder/releases/8.1.0/linux/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

hammer repository   create  --name Splunk  --content-type yum  --organization-id 1 \
--product $OS --download-policy immediate --mirror-on-sync false

hammer repository upload-content --name Splunk --organization-id 1 --product CentOS \
--path /var/www/html/pub/packages/Splunk/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

hammer repository upload-content --name Splunk --organization-id 1 --product CentOS \
--path /var/www/html/pub/packages/Splunk/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

hammer content-view add-repository --name contentview01 --repository Splunk --organization-id 1
hammer content-view publish --name contentview01 --organization-id 1 #--async
contentVersion=$( hammer --output csv content-view version  list --content-view contentview01  --organization-id 1 | grep Library | awk -F, '{print $3}')
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev --version $contentVersion