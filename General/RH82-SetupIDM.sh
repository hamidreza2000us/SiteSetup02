#requires at least 3GB of memory, otherwise the installtion will fail during createing certificates
#yum install -y ipa-server ipa-server-dns
yum module install -y idm:DL1/dns
yum -y install augeas

export HOSTNAME=${HOSTNAME:="${hostname}"}
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
cat > /tmp/hostsconfig << EOF
defvar mypath /files/etc/hosts
ins 01 after \$mypath/2/
set \$mypath/01/ipaddr  $IP
set \$mypath/01/canonical $HOSTNAME
save
EOF
augtool -s -f /tmp/hostsconfig

#cat > /tmp/resolveconfig << EOF
#defvar mypath /files/etc/resolv.conf
#rm  \$mypath/nameserver
#set \$mypath/nameserver[last()+1] $IP
#save
#EOF
#augtool -s -f /tmp/resolveconfig

if [ $(dig +short -x $(dig +short $(hostname -f)) ) != $(hostname -f). ] 
  then echo "DNS is not setup correctly"; 
  exit;
fi

ipa-server-install --realm MYHOST.COM --ds-password Iahoora@123 --admin-password Iahoora@123 --unattended --setup-dns --auto-reverse --reverse-zone=1.168.192.in-addr.arpa. --forwarder 192.168.1.149

firewall-cmd --add-service=freeipa-ldaps  --add-service=freeipa-ldap --add-service=dns  --add-service=ntp  --permanent
firewall-cmd --reload

systemctl enable chronyd
systemctl restart chronyd

kinit admin
ipa dnszone-mod myhost.com. --allow-sync-ptr=TRUE
ipa dnszone-mod 1.168.192.in-addr.arpa. --dynamic-update=TRUE
