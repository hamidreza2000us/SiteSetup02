yum install -y yum-utils
yum -y localinstall http://yum.puppetlabs.com/puppet-release-el-7.noarch.rpm
yum -y localinstall https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
yum -y localinstall https://yum.theforeman.org/releases/1.24/el7/x86_64/foreman-release.rpm
yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/3.14/katello/el7/x86_64/katello-repos-latest.rpm 

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

foreman-installer --enable-foreman-plugin-bootdisk   --enable-foreman-plugin-discovery   --enable-foreman-plugin-setup  \
--enable-foreman-plugin-ansible --enable-foreman-plugin-monitoring --enable-foreman-plugin-templates  --enable-foreman-cli \
--enable-foreman-cli-discovery --enable-foreman-cli-openscap --enable-foreman-cli-remote-execution --enable-foreman-cli-tasks \
--enable-foreman-cli-templates  --enable-foreman-cli-ansible --enable-foreman-proxy --enable-foreman-proxy-plugin-ansible  \
--enable-foreman-proxy-plugin-discovery --enable-foreman-proxy-plugin-monitoring
foreman-maintain service restart

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

#foreman-maintain service restart
##############################
mount -o ro /dev/cdrom /mnt/cdrom
ln -s /mnt/cdrom /var/www/html/pub/cdrom
#--server https://foreman.myhost.com  --username admin  --password ahoora 
hammer organization create --name myorg
hammer product create --name CentOS --label CentOS --organization myorg
hammer repository   create  --name myorg    --content-type yum  --organization myorg  --name BaseOS  --product CentOS --url https://foreman.myhost.com/pub/cdrom/
hammer repository synchronize  --organization myorg --product CentOS  --name BaseOS --async
hammer activation-key create --name mykey01 --organization myorg --lifecycle-environment Library
###############################
curl --insecure --output katello-ca-consumer-latest.noarch.rpm  https://foreman.myhost.com/pub/katello-ca-consumer-latest.noarch.rpm
yum localinstall -y katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org="myorg" --activationkey=mykey01
yum -y install katello-host-tools
yum -y install katello-host-tools-tracer
yum -y install katello-agent
################################
hammer auth-source ldap create --name idm.myhost.com --host idm.myhost.com --server-type free_ipa \
--account admin --account-password "Iahoora@123" --base-dn "dc=myhost ,dc=com"  --onthefly-register true \
--attr-login uid  --attr-firstname givenName --attr-lastname sn --attr-mail mail
################################
hammer domain update --name myhost.com --organizations myorg
hammer subnet create --name subnet13 --network 192.168.13.0 --mask 255.255.255.0 --gateway 192.168.13.2  \
--dns-primary 192.168.13.11 --ipam DHCP --boot-mode DHCP --from 192.168.13.50 --to 192.168.13.100  \
--dhcp foreman.myhost.com  --tftp foreman.myhost.com --discovery-id 1 --httpboot-id 1 --template-id 1 --domains myhost.com --organization myorg
################################
mount -o ro /dev/cdrom /mnt/cdrom
hammer medium create --name CentOSRepo --os-family Redhat --path http://foreman.myhost.com/pub/cdrom/ --organizations myorg
hammer os create --architectures x86_64 --name myCent --media CentOSRepo --partition-tables "Kickstart default" --major 7 --minor 7
  
hammer lifecycle-environment create  --description "dev"  --name dev  --label dev --organization myorg --prior Library
hammer lifecycle-environment create  --description "qa"  --name qa  --label qa --organization myorg --prior dev
hammer lifecycle-environment create  --description "prod"  --name prod  --label prod --organization myorg --prior qa
   
hammer content-view create --name contentview01 --label contentview01 --organization myorg 
hammer content-view add-repository --name contentview01 --repository BaseOS --organization myorg 
hammer content-view publish --name contentview01 --organization myorg --async
hammer content-view  version promote --organization myorg  --content-view contentview01 --to-lifecycle-environment dev
   
 hammer hostgroup create --name hostgroup02 --lifecycle-environment Library --subnet subnet13 \
 --operatingsystem "CentOS 7"  --architecture x86_64 --root-pass Iahoora@123 --organization myorg \
 --operatingsystem "myCent 7.7" --medium CentOSRepo --partition-table "Kickstart default"  --pxe-loader 'PXELinux BIOS'  \
 --domain myhost.com --root-pass Iahoora@123 --subnet subnet13    --content-view contentview01
 
  hammer global-parameter set --name package_upgrade --parameter-type boolean --value false
  hammer global-parameter set --name use-ntp --parameter-type boolean --value false
  hammer global-parameter set --name time-zone --parameter-type string --value Asia/Tehran
   hammer global-parameter set --name ntp-server --parameter-type string --value 192.168.13.11
 
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
#ipa hostgroup-add hostgroup02
#ipa automember-add --type=hostgroup hostgroup02
#ipa automember-add-condition --key=userclass --type=hostgroup hostgroup02
#ipa automember-add-condition --key=userclass --type=hostgroup --inclusive-regex=^web  hostgroup02


  
