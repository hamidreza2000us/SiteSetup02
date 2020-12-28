#Copy SiteSetup to the /root
WEBIP=192.168.1.111
IDMIP=192.168.1.112
SATIP=192.168.1.113

#mkdir -p ~/SiteSetup/{Backups,Files,Images,ISOs,RPMs,Yaml}
cd /mnt/Mount/Yaml

cat > /root/.inventory << EOF
[hosts]
rhvm.myhost.com
rhvh01.myhost.com

[ipaserver]
192.168.1.112
[ipaserver:vars]
ipaserver=idm.myhost.com
ipaserver_ip_addresses=192.168.1.112
ipaserver_hostname=idm.myhost.com
ipaserver_domain=myhost.com
ipaserver_realm=MYHOST.COM
ipaserver_setup_dns=true
ipaserver_auto_forwarders=true
ipadm_password=Iahoora@123
ipaadmin_password=Iahoora@123
ipaserver_setup_dns=true
ipaserver_no_host_dns=true
ipaserver_auto_reverse=true
ipaserver_no_dnssec_validation=true
ipaserver_forwarders=192.168.1.1
ipaserver_reverse_zones=1.168.192.in-addr.arpa.
ipaserver_allow_zone_overlap=true

[ipaclients]
192.168.1.113
[ipaclients:vars]
ipaclient_domain=myhost.com
ipaadmin_principal=admin
ipaadmin_password=Iahoora@123
ipasssd_enable_dns_updates=yes
ipaclient_all_ip_addresses=yes
ipaclient_mkhomedir=yes
ipaclient_force_join=yes
[ipaservers]
192.168.1.112
[ipaserver:vars]
ipaadmin_password=Iahoora@123

EOF

ansible-playbook -i ~/.inventory uploadImage.yml
ansible-playbook -i ~/.inventory uploadISO.yml
#create a vm based on rh8.3
ansible-playbook -i ~/.inventory create-vmFromImage.yml -e VMName=Template8.3 -e VMMemory=2GiB -e VMCore=1 \
-e ImageName=rhel-8.3-x86_64-kvm.qcow2 -e HostName=template8.3.myhost.com
#create a tempalate based on previous machine
ansible-playbook -i ~/.inventory create-template.yml -e VMName=Template8.3 -e VMTempate=Template8.3
#create a server for idm server baed on previous template
ansible-playbook -i ~/.inventory create-vmFromTemplateWIP.yml -e VMName=idm -e VMMemory=4GiB -e VMCore=4  \
-e HostName=idm.myhost.com -e VMTempate=Template8.3 -e VMISO=rhel-8.3-x86_64-dvd.iso -e VMIP=${IDMIP}

#scp -o StrictHostKeyChecking=no   /root/SiteSetup/ISOs/rhel-8.3-x86_64-dvd.iso ${IDMIP}:~/

#clearing the previous host (in the lab environemnt)
sed -i "/${IDMIP}/d" /root/.ssh/known_hosts
#mount the cdrom on idm
ssh -o StrictHostKeyChecking=no ${IDMIP} "mount -o loop,ro /dev/sr0 /mnt/cdrom"

#ansible-galaxy collection install freeipa.ansible_freeipa

#cd ~/.ansible/collections/ansible_collections/freeipa/ansible_freeipa/roles/ipaserver/
#ansible-playbook -i .inventory ~/.ansible/collections/ansible_collections/freeipa/ansible_freeipa/playbooks/install-server.yml
#ssh ${IDMIP} "yumdownloader ansible-freeipa-0.1.12-6.el8"
#scp ${IDMIP}:~/ansible-freeipa-0.1.12-6.el8.noarch.rpm /root/SiteSetup/RPMs/

#install FreeIPA package (ansible-galaxy package seems buggy)
yum localinstall -y /mnt/Mount/Files/ansible-freeipa-0.1.12-6.el8.noarch.rpm
 
#[defaults]
#cat >  /root/SiteSetup/Yaml/ansible.cfg << EOF
#roles_path   = /usr/share/ansible/roles
#library      = /usr/share/ansible/plugins/modules
#module_utils = /usr/share/ansible/plugins/module_utils
#EOF
#
#cat > /root/SiteSetup/Yaml/setupIDM.yml << EOF
#---
#- name: Playbook to configure IPA server
#  hosts: ipaserver
#  become: true
##  vars_files:
##  - playbook_sensitive_data.yml
#
#  roles:
#  - role: ipaserver
#    state: present
#EOF

#cd /root/SiteSetup/Yaml

#install IDM on the server
ansible-playbook -i .inventory  setupIDM.yml
ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. rhvm --a-ip-address=192.168.1.120  --a-create-reverse '

DNS=${IDMIP}
nmcli con mod ovirtmgmt ipv4.dns $DNS
nmcli con up $con

#install redhat satellite
####################################################################
#cd /root/SiteSetup/Yaml

#setup a new machine based on rh7.9 for satellite
ansible-playbook -i ~/.inventory create-vmFromImage.yml -e VMName=Template7.9 -e VMMemory=2GiB \
-e VMCore=1 -e ImageName=rhel-server-7.9-x86_64-kvm.qcow2 -e HostName=template7.9.myhost.com
#create a template from previous machine
ansible-playbook -i ~/.inventory create-template.yml -e VMName=Template7.9 -e VMTempate=Template7.9
#create a machine for satellite based on previous template
ansible-playbook -i ~/.inventory create-vmFromTemplateWIP-satellite.yml -e VMName=satellite \
-e VMMemory=16GiB -e VMCore=6 -e VMDiskSize=100GiB -e HostName=satellite.myhost.com \
-e VMTempate=Template7.9 -e VMISO=rhel-server-7.9-x86_64-dvd.iso -e VMIP=${SATIP} -e VMDNS=${IDMIP}

#clearing the host id (in lab environemnt)
sed -i "/${SATIP}/d" /root/.ssh/known_hosts

#create a partiton on the satellite and mount it as /var
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << 'EOF'
mount -o loop,ro /dev/sr0 /mnt/cdrom
yum -y install lvm2
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
EOF


#cat > setupIDMClient.yml << EOF
#- name: Playbook to configure IPA clients with username/password
#  hosts: ipaclients
#  become: true
#
#  roles:
#  - role: ipaclient
#    state: present
#EOF
IDMPass=Iahoora@123
IDMDomain=myhost.com
IDMHOSTNAME=idm.myhost.com

ipa-client-install --principal admin --password $IDMPass  --unattended  \
--domain $IDMDomain --enable-dns-updates --all-ip-addresses --mkhomedir \
--automount-location=default  --server $IDMHOSTNAME --force-join

ssh -o StrictHostKeyChecking=no 192.168.1.120 /bin/bash << 'EOF'
con=$( nmcli -g UUID,type con sh --active | grep ethernet | awk -F: '{print $1}' | head -n1)
nmcli con mod ${con}  ipv4.dns 192.168.1.112
nmcli con up $con

cat > AnswerFile.env << EOF2
# OTOPI answer file, generated by human dialog
[environment:default]
QUESTION/1/OVAAALDAP_LDAP_AAA_PROFILE=str:idm.myhost.com
QUESTION/1/OVAAALDAP_LDAP_AAA_USE_VM_SSO=str:yes
QUESTION/1/OVAAALDAP_LDAP_BASE_DN=str:dc=myhost,dc=com
QUESTION/1/OVAAALDAP_LDAP_PASSWORD=str:Iahoora@123
QUESTION/1/OVAAALDAP_LDAP_PROFILES=str:6
QUESTION/1/OVAAALDAP_LDAP_PROTOCOL=str:plain
QUESTION/1/OVAAALDAP_LDAP_SERVERSET=str:1
QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE=str:done
QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE_LOGIN_PASSWORD=str:Iahoora@123
QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE_LOGIN_USER=str:admin
QUESTION/1/OVAAALDAP_LDAP_USER=str: uid=admin,cn=users,cn=accounts,dc=myhost,dc=com
QUESTION/1/OVAAALDAP_LDAP_USE_DNS=str:no
QUESTION/2/OVAAALDAP_LDAP_SERVERSET=str:idm.myhost.com
EOF2

ovirt-engine-extension-aaa-ldap-setup --config-append=~/AnswerFile.env
systemctl restart ovirt-engine
EOF
#ipa dnsrecord-add myhost.com rhvm  --a-ip-address=192.168.1.120  --a-create-reverse
 
ansible-playbook -i ~/.inventory  setupIDMClient.yml
######################################################checked
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. satellite --a-rec 192.168.1.113 '
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add 1.168.192.in-addr.arpa. 113 --ptr-rec satellite.myhost.com. '

scp -o StrictHostKeyChecking=no   /root/SiteSetup/ISOs/satellite-6.8.0-rhel-7-x86_64-dvd.iso ${SATIP}:/var/
ssh -o StrictHostKeyChecking=no ${SATIP} "mount -o loop,ro /var/satellite-6.8.0-rhel-7-x86_64-dvd.iso /mnt/sat"
ssh -o StrictHostKeyChecking=no ${SATIP} "cd /mnt/sat/ &&  ./install_packages"
ssh -o StrictHostKeyChecking=no ${SATIP} satellite-installer --scenario satellite \
--foreman-initial-organization behsa \
--foreman-cli-foreman-url "https://${domain}" \
--foreman-cli-username admin \
--foreman-cli-password ${pass}  --foreman-initial-admin-password ${pass} \
--foreman-proxy-realm true --foreman-proxy-realm-principal foremanuser@$idmrealm \

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
ssh -o StrictHostKeyChecking=no ${SATIP} hammer subscription upload --file manifest_satellite-test_20201209T183955Z.zip --organization-id 1 --repository-url http://rhvh01.myhost.com/RHEL


#ansible-galaxy install oasis_roles.satellite