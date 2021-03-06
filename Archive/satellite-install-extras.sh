
##############################################################################################
#mkdir -p ~/SiteSetup/{Backups,Files,Images,ISOs,RPMs,Yaml}
#scp -o StrictHostKeyChecking=no   /root/SiteSetup/ISOs/rhel-8.3-x86_64-dvd.iso ${IDMIP}:~/

#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. rhvm --a-ip-address=192.168.1.120  --a-create-reverse '

#ansible-galaxy collection install freeipa.ansible_freeipa

#cd ~/.ansible/collections/ansible_collections/freeipa/ansible_freeipa/roles/ipaserver/
#ansible-playbook -i .inventory ~/.ansible/collections/ansible_collections/freeipa/ansible_freeipa/playbooks/install-server.yml
#ssh ${IDMIP} "yumdownloader ansible-freeipa-0.1.12-6.el8"
#scp ${IDMIP}:~/ansible-freeipa-0.1.12-6.el8.noarch.rpm /root/SiteSetup/RPMs/


#ssh -o StrictHostKeyChecking=no 192.168.1.120 /bin/bash << 'EOF'
#con=$( nmcli -g UUID,type con sh --active | grep ethernet | awk -F: '{print $1}' | head -n1)
#nmcli con mod ${con}  ipv4.dns 192.168.1.112
#nmcli con up $con

#cat > AnswerFile.env << EOF2
## OTOPI answer file, generated by human dialog
#[environment:default]
#QUESTION/1/OVAAALDAP_LDAP_AAA_PROFILE=str:idm.myhost.com
#QUESTION/1/OVAAALDAP_LDAP_AAA_USE_VM_SSO=str:yes
#QUESTION/1/OVAAALDAP_LDAP_BASE_DN=str:dc=myhost,dc=com
#QUESTION/1/OVAAALDAP_LDAP_PASSWORD=str:Iahoora@123
#QUESTION/1/OVAAALDAP_LDAP_PROFILES=str:6
#QUESTION/1/OVAAALDAP_LDAP_PROTOCOL=str:plain
#QUESTION/1/OVAAALDAP_LDAP_SERVERSET=str:1
#QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE=str:done
#QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE_LOGIN_PASSWORD=str:Iahoora@123
#QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE_LOGIN_USER=str:admin
#QUESTION/1/OVAAALDAP_LDAP_USER=str: uid=admin,cn=users,cn=accounts,dc=myhost,dc=com
#QUESTION/1/OVAAALDAP_LDAP_USE_DNS=str:no
#QUESTION/2/OVAAALDAP_LDAP_SERVERSET=str:idm.myhost.com
#EOF2

#ovirt-engine-extension-aaa-ldap-setup --config-append=~/AnswerFile.env
#systemctl restart ovirt-engine
#EOF
#ipa dnsrecord-add myhost.com rhvm  --a-ip-address=192.168.1.120  --a-create-reverse


#ipa-client-install --principal admin --password $IDMPass  --unattended  \
#--domain ${Domain} --enable-dns-updates --all-ip-addresses --mkhomedir \
#--automount-location=default  --server ${IDMHost}.${Domain} --force-join

#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. satellite --a-rec 192.168.1.113 '
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add 1.168.192.in-addr.arpa. 113 --ptr-rec satellite.myhost.com. '

#ansible-galaxy install oasis_roles.satellite