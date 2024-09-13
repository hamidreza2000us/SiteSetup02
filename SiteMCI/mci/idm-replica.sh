
yum module disable idm:client -y
yum module enable idm:DL1/{dns,adtrust} -y
yum distro-sync -y
yum module install -y idm:DL1/{dns,adtrust}

IDMIP=172.17.58.98
SATIP=172.16.49.97
IDMForwarder=172.18.9.3

Domain=idm.mci.ir
RHVHHost=rhvh01
IDMHost=ipa02
SatHost=satellite
ORG=MCI

IDMPass=Iahoora@123
SatPass=Iahoora@123
DefaultPass=Iahoora@123


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

echo "${IDMPass}" | kinit admin
time ipa-replica-install --realm ${Domain^^} --admin-password ${IDMPass} --unattended --hostname ${IDMHost}.${Domain}  \
--ip-address ${IDMIP} --domain ${Domain} --auto-forwarders --no-host-dns --allow-zone-overlap --setup-dns --no-host-dns --auto-reverse \
--no-dnssec-validation  --forwarder ${IDMForwarder} --reverse-zone=172.in-addr.arpa. --reverse-zone=168.192.in-addr.arpa. --reverse-zone=10.in-addr.arpa. 

ipa-ca-install -p ${IDMPass}