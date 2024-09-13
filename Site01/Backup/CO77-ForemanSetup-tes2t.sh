yum install -y yum-utils
yum -y localinstall https://yum.theforeman.org/releases/2.0/el7/x86_64/foreman-release.rpm
yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/3.15/katello/el7/x86_64/katello-repos-latest.rpm
yum -y localinstall https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
yum -y localinstall https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install foreman-release-scl

yum -y install katello
foreman-installer --scenario katello

if  [  $( firewall-cmd --query-service=RH-Satellite-6) == 'no'  ] ; then firewall-cmd --permanent --add-service=RH-Satellite-6 ; fi
firewall-cmd --reload

foreman-rake permissions:reset password=ahoora
cat >  ~/.hammer/cli.modules.d/foreman.yml << EOF
:foreman:
  # Credentials. You'll be asked for the interactively if you leave them blank here
  :username: 'admin'
  :password: 'ahoora'
  :host: 'https://foreman.myhost.com'

  # Check API documentation cache status on each request
  :refresh_cache: false

  # API request timeout in seconds, set -1 for infinity
  :request_timeout: 120
EOF


#foreman-installer --enable-foreman-plugin-bootdisk   --enable-foreman-plugin-discovery   --enable-foreman-plugin-setup  \
#--enable-foreman-plugin-ansible --enable-foreman-plugin-monitoring --enable-foreman-plugin-templates  --enable-foreman-cli \
#--enable-foreman-cli-discovery --enable-foreman-cli-openscap --enable-foreman-cli-remote-execution --enable-foreman-cli-tasks \
#--enable-foreman-cli-templates  --enable-foreman-cli-ansible --enable-foreman-proxy --enable-foreman-proxy-plugin-ansible  \
#--enable-foreman-proxy-plugin-discovery --enable-foreman-proxy-plugin-monitoring --enable-foreman-proxy-plugin-remote-execution-ssh
#foreman-maintain service restart


foreman-installer \
--foreman-proxy-dhcp true \
--foreman-proxy-dhcp-interface ens33 \
--foreman-proxy-dhcp-managed true \
--foreman-proxy-dhcp-range="192.168.13.50 192.168.13.100" \
--foreman-proxy-dhcp-nameservers 192.168.13.11 \
--foreman-proxy-dhcp-gateway 192.168.13.2 \
--foreman-proxy-tftp true \
--foreman-proxy-tftp-managed true \
--foreman-proxy-tftp-servername foreman.myhost.com 

foreman-maintain packages install -y rhel-system-roles
hammer ansible roles import --role-names rhel-system-roles.timesync --proxy-id 1
hammer ansible variables create --variable timesync_ntp_servers --variable-type array --override true \
--default-value  '[{"hostname":"idm.myhost.com"},{"iburst":"yes"}]' --ansible-role  rhel-system-roles.timesync --hidden-value false

#foreman-maintain service restart
##############################
#hammer organization create --name Default_Organization
#ln -s /mnt/cdrom /var/www/html/pub/cdrom
mount -o ro /dev/cdrom /mnt/cdrom
mkdir -p /var/www/html/pub/media/Centos7.7/
cp -r /mnt/cdrom /var/www/html/pub/media/Centos7.7
#curl http://mirror.centos.org/centos/7.8.2003/os/x86_64/images/boot.iso -o /var/www/html/pub/media/Centos7.7/images/boot.iso
restorecon -Rv /var/www/html/pub/media/Centos7.7
hammer product create --name CentOS --label CentOS --organization-id 1
hammer repository   create  --name BaseOS    --content-type yum  --organization-id 1  --name BaseOS  \
--product CentOS --url http://foreman.myhost.com/pub/media/Centos7.7 --download-policy immediate --mirror-on-sync false

hammer repository synchronize  --organization-id 1 --product CentOS  --name BaseOS --async
hammer activation-key create --name mykey01 --organization-id 1 --lifecycle-environment Library
hammer activation-key add-subscription --name mykey01 --subscription CentOS --organization-id 1
###############################
curl --insecure --output katello-ca-consumer-latest.noarch.rpm  https://foreman.myhost.com/pub/katello-ca-consumer-latest.noarch.rpm
yum localinstall -y katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org="Default_Organization" --activationkey=mykey01
yum -y install katello-host-tools
yum -y install katello-host-tools-tracer
yum -y install katello-agent
################################
hammer auth-source ldap create --name idm.myhost.com --host idm.myhost.com --server-type free_ipa \
--account admin --account-password "Iahoora@123" --base-dn "dc=myhost ,dc=com"  --onthefly-register true \
--attr-login uid  --attr-firstname givenName --attr-lastname sn --attr-mail mail
################################
hammer domain update --name myhost.com --organization-id 1
hammer subnet create --name subnet13 --network 192.168.13.0 --mask 255.255.255.0 --gateway 192.168.13.2  \
--dns-primary 192.168.13.11 --ipam DHCP --boot-mode DHCP --from 192.168.13.50 --to 192.168.13.100  \
--dhcp foreman.myhost.com  --tftp foreman.myhost.com --discovery-id 1 --httpboot-id 1 --template-id 1 --domains myhost.com --organization-id 1
################################
hammer medium create --name CentOSRepo --os-family Redhat --path http://foreman.myhost.com/pub/media/Centos7.7 --organization-id 1

hammer os create --architectures x86_64 --name myCent --media CentOSRepo --partition-tables "Kickstart default" --major 7 --minor 7 \
--provisioning-templates "PXELinux global default" --family "Redhat"

hammer template add-operatingsystem --name "PXELinux global default" --operatingsystem "myCent 7.7"
 
hammer lifecycle-environment create  --description "dev"  --name dev  --label dev --organization-id 1 --prior Library
hammer lifecycle-environment create  --description "qa"  --name qa  --label qa --organization-id 1 --prior dev
hammer lifecycle-environment create  --description "prod"  --name prod  --label prod --organization-id 1 --prior qa
   
hammer content-view create --name contentview01 --label contentview01 --organization-id 1 
hammer content-view add-repository --name contentview01 --repository BaseOS --organization-id 1 
hammer content-view publish --name contentview01 --organization-id 1 #--async
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev
   
hammer hostgroup create --name hostgroup01 --lifecycle-environment Library --subnet subnet13  \
  --architecture x86_64 --root-pass Iahoora@123 --organization-id 1 \
 --operatingsystem "myCent 7.7" --medium CentOSRepo --partition-table "Kickstart default"  \
 --pxe-loader 'PXELinux BIOS'   --domain myhost.com --root-pass Iahoora@123 --subnet subnet13    \
 --content-view contentview01 --content-source foreman.myhost.com --realm MYHOST.COM 


hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_server --parameter-type string --value idm.myhost.com
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_domain --parameter-type string --value MYHOST.COM
hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles rhel-system-roles.timesync 
# --ansible-roles rhel-system-roles.timesync
# --group-parameters-attributes "name=freeipa_server\,value=idm.myhost.com\,parameter_type=string,name=freeipa_domain\,value=MYHOST.COM\,parameter_type=string"

 
hammer global-parameter set --name package_upgrade --parameter-type boolean --value false
hammer global-parameter set --name use-ntp --parameter-type boolean --value false
hammer global-parameter set --name time-zone --parameter-type string --value Asia/Tehran
hammer global-parameter set --name ntp-server --parameter-type string --value 192.168.13.11
 
hammer realm create --name MYHOST.COM --realm-type FreeIPA --realm-proxy-id 1 --organization-id 1
 
foreman-prepare-realm admin foremanuser
mv /root/freeipa.keytab /etc/foreman-proxy
chown foreman-proxy:foreman-proxy /etc/foreman-proxy/freeipa.keytab
mv /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
update-ca-trust enable
update-ca-trust
foreman-installer --foreman-proxy-realm true --foreman-proxy-realm-keytab /etc/foreman-proxy/freeipa.keytab  \
--foreman-proxy-realm-principal foremanuser@MYHOST.COM  --foreman-proxy-realm-listen-on "https" \
--foreman-proxy-realm-provider "freeipa" 

#run on idm server
#ipa hostgroup-add hostgroup01
#ipa automember-add --type=hostgroup hostgroup01
#ipa automember-add-condition --key=userclass --type=hostgroup hostgroup01
#ipa automember-add-condition --key=userclass --type=hostgroup --inclusive-regex=^web  hostgroup01

cat >  /tmp/packages << EOF
bash-completion
tuned
chrony
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
EOF
hammer template create --name "Kickstart default custom packages" --type snippet --file /tmp/packages --organization-id 1

cat >  /tmp/post << EOF
#%addon com_redhat_kdump --disable
#%end
systemctl disable kdump.service
systemctl mask kdump.service
#ls -d /etc/yum.repos.d/* | grep -v redhat.repo |xargs -I % mv % %.bkp
EOF
hammer template create --name "Kickstart default custom post" --type snippet --file /tmp/post --organization-id 1

 hammer host create --name myhost01 --hostgroup hostgroup01 --content-source foreman.myhost.com \
 --medium CentOSRepo --partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"  \
 --organization-id 1  --location "Default Location" --interface mac=00:0C:29:2B:7B:C8

hammer settings set --name ansible_ssh_private_key_file --value /usr/share/foreman-proxy/.ssh/id_rsa_foreman_proxy 
 
pubkey=$(curl -k https://foreman.myhost.com:9090/ssh/pubkey)
hammer global-parameter set --name remote_execution_ssh_keys  --parameter-type array --value "[$pubkey]"
 
hammer global-parameter set --name redhat_install_agent --parameter-type boolean --value true
hammer global-parameter set --name subscription_manager --parameter-type boolean --value true
hammer global-parameter set --name redhat_install_host_tools --parameter-type boolean --value true
hammer global-parameter set --name atomic --parameter-type boolean --value false
hammer global-parameter set --name subscription_manager_certpkg_url --parameter-type string --value https://foreman.myhost.com/pub/katello-ca-consumer-latest.noarch.rpm
hammer global-parameter set --name kt_activation_keys --parameter-type string --value mykey01
hammer global-parameter set --name freeipa_server --parameter-type string --value idm.myhost.com
hammer global-parameter set --name freeipa_domain --parameter-type string --value MYHOST.COM
hammer global-parameter set --name realm.realm_type --parameter-type string --value FreeIPA

#hammer global-parameter set --name subscription_manager_pool --parameter-type string --value 40288d8c7460828201746e68e6990001
hammer global-parameter set --name enable-epel --parameter-type boolean --value false



###############################################################################33
#hammer policy create --organization-id 1 --period monthly --day-of-month 1 --deploy-by ansible --hostgroups hostgroup01 --name policy01  --scap-content-profile xccdf_org.ssgproject.content_profile_ospp  --scap-content-id 8
