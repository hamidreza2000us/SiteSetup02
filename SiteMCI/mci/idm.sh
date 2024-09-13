#Mount the Hard Drive Containing Files,ISOs,...
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

##############################################################################

hostnamectl set-hostname ${IDMHost}.${Domain}

#mount the cdrom on idm
mkdir /mnt/cdrom
mount -o loop,ro /dev/sr0 /mnt/cdrom
cat > /etc/yum.repos.d/cd.repo << EOF
[cdrom-base]
name=cdrom-base
baseurl=file:///mnt/cdrom/BaseOS

[cdrom-app]
name=cdrom-app
baseurl=file:///mnt/cdrom/AppStream
EOF

nmcli con mod ens192 ipv4.dns 172.18.9.3,172.18.9.4 ipv4.dns-search mci.ir
nmcli con up ens192

sed -i '/^pool.*/d' /etc/chrony.conf
sed -i '3iserver 172.20.20.34 iburst' /etc/chrony.conf
sed -i '3iserver 172.20.20.33 iburst' /etc/chrony.conf
sed -i '25i allow 172.16.0.0/12' /etc/chrony.conf
sed -i '25i allow 192.168.0.0/16' /etc/chrony.conf
sed -i '25i allow 10.0.0.0/8' /etc/chrony.conf

systemctl restart chronyd
chronyc sources
 
#install FreeIPA package (ansible-galaxy package seems buggy)
yum module install -y idm:DL1/dns

ReverseIP=$(echo ${IDMIP} | awk -F. '{print $3"."$2"."$1".in-addr.arpa."}')

time ipa-server-install --realm ${Domain^^} --ds-password ${IDMPass} --admin-password ${IDMPass} --unattended \
--hostname ${IDMHost}.${Domain}  --ip-address ${IDMIP} --domain ${Domain} --auto-forwarders --no-host-dns \
--allow-zone-overlap --setup-dns --no-host-dns --auto-reverse --no-dnssec-validation  \
--forwarder ${IDMForwarder} --reverse-zone=172.in-addr.arpa. --reverse-zone=168.192.in-addr.arpa. --reverse-zone=10.in-addr.arpa.


if  [  $( firewall-cmd --query-service=freeipa-ldap) == 'no'  ] ; then firewall-cmd --permanent --add-service=freeipa-ldap ; fi
if  [  $( firewall-cmd --query-service=freeipa-ldaps) == 'no'  ] ; then firewall-cmd --permanent --add-service=freeipa-ldaps ; fi
if  [  $( firewall-cmd --query-service=dns) == 'no'  ] ; then firewall-cmd --permanent --add-service=dns ; fi
if  [  $( firewall-cmd --query-service=ntp) == 'no'  ] ; then firewall-cmd --permanent --add-service=ntp ; fi
firewall-cmd --reload
if [ $(systemctl is-enabled chronyd) == 'disabled'  ]
then
  systemctl enable chronyd  
fi
systemctl restart chronyd


echo ${IDMPass} | kinit admin
ipa dnsconfig-mod --allow-sync-ptr=true
ipa dnszone-mod ${Domain} --allow-sync-ptr=true
ipa sudorule-add AdminRule --hostcat=all  --cmdcat=all --runasusercat=all
ipa sudorule-add-option AdminRule  --sudooption='!authenticate'
ipa sudorule-add-user AdminRule --users=admin
#   allow-query {127.0.0.1; 172.0.0.0/8; 10.0.0.0/8 ; 192.168.0.0/16; };
#   allow-recursion { 127.0.0.1; 172.0.0.0/8; 10.0.0.0/8 ; 192.168.0.0/16;  };

#not tested
echo 'allow-query { any; };' >> /etc/named/ipa-options-ext.conf
echo 'allow-recursion { any; };' >> /etc/named/ipa-options-ext.conf
systemctl restart named-pkcs11

#ip of ntp server should be pass here instead of IDMIP or IDM should be configured to be a ntp server
ipa  dnsrecord-add ${Domain}  _ntp._udp --srv-priority 0 --srv-weight 100 --srv-port 123 --srv-target ${IDMIP}