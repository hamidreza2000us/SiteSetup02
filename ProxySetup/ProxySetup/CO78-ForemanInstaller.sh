source ~/proxysetup/variables.sh
domain=$ProxyHOSTNAME
domainname=$IDMDomain
gw=$ProxyGW
dns=$IDMIP
interface=$(nmcli dev | grep connected | awk  '{print $1}')
subnetname=$(echo ${ProxyIP} | awk -F. '{print "subnet"$3}')
IPRange=$(echo ${ProxyIP} | awk -F. '{print $1"."$2"."$3}')
startip=$IPRange.50
endip=$IPRange.100
network=$IPRange.0
netmask=255.255.255.0
idmuser=admin
idmhost=$IDMHOSTNAME
idmpass=$IDMPass
idmdn=$(echo $IDMDomain | awk -F. '{print "dc="$1",dc="$2}')
idmrealm=$IDMRealm
pass=Iahoora@123
################################################################installation#########################################################################
########################installation#############################
foreman-installer --foreman-proxy-realm true --foreman-proxy-realm-principal foremanuser@$idmrealm \
--enable-foreman-proxy-plugin-discovery    \
--enable-foreman-proxy-plugin-remote-execution-ssh \
--enable-foreman-proxy-plugin-ansible \
--foreman-proxy-http true \
--foreman-proxy-bmc true \
--foreman-proxy-plugin-discovery-install-images true \
--enable-foreman-proxy-plugin-openscap 

#--foreman-proxy-dhcp true \
#--foreman-proxy-dhcp-interface $interface \
#--foreman-proxy-dhcp-managed true \
#--foreman-proxy-dhcp-range="$startip $endip" \
#--foreman-proxy-dhcp-nameservers $dns \
#--foreman-proxy-dhcp-gateway $gw \
#--foreman-proxy-tftp true \
#--foreman-proxy-tftp-managed true \
#--foreman-proxy-tftp-servername $domain \
#--foreman-proxy-templates

echo -e "$idmpass" | foreman-prepare-realm $idmuser foremanuser
/usr/bin/cp -f /root/freeipa.keytab /etc/foreman-proxy
chown foreman-proxy:foreman-proxy /etc/foreman-proxy/freeipa.keytab
/usr/bin/cp  -f /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
update-ca-trust enable
update-ca-trust

#######################firewall config##############################
if  [  $( firewall-cmd --query-service=RH-Satellite-6) == 'no'  ] ; then firewall-cmd --permanent --add-service=RH-Satellite-6 ; fi
firewall-cmd --add-port=8443/tcp --permanent
firewall-cmd --reload

#########################ansible config##################
sed -i -e 's/^#callback_whitelist = timer, mail/callback_whitelist = foreman/g' /etc/ansible/ansible.cfg
echo "[callback_foreman]" >> /etc/ansible/ansible.cfg
echo "url = https://$domain" >> /etc/ansible/ansible.cfg
echo "ssl_cert = /etc/foreman-proxy/ssl_cert.pem" >> /etc/ansible/ansible.cfg
echo "ssl_key = /etc/foreman-proxy/ssl_key.pem" >> /etc/ansible/ansible.cfg
echo "verify_certs = /etc/foreman-proxy/ssl_ca.pem" >> /etc/ansible/ansible.cfg






