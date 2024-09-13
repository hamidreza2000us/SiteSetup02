#This script get some resources and setup idm and chrony service to be use by other services
#The DNS server is also setup and act as primary dns server for the domain
#ip a sh
#ip a a 192.168.13.11/24 dev ens160
#ip route add default via 192.168.13.2 dev ens160
mkdir /root/Site01
#pull the script below:
# curl http://192.168.13.10/Site01/02-IDMHostsetup.sh -o /root/Site01/02-IDMHostsetup.sh

mkdir /root/Site01
curl http://192.168.13.10/Site01/RH8-BaseSystem.sh -o /root/Site01/RH8-BaseSystem.sh
sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/RH8-BaseSystem.sh
bash /root/Site01/RH8-BaseSystem.sh
curl http://dnsf.myhost.com/Site01/RH82-IDMSetup.sh -o /root/Site01/RH82-IDMSetup.sh
sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/RH82-IDMSetup.sh
bash /root/Site01/RH82-IDMSetup.sh
curl http://dnsf.myhost.com/Site01/RH7-8-SetupChrony.sh -o /root/Site01/RH7-8-SetupChrony.sh
sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/RH7-8-SetupChrony.sh
bash /root/Site01/RH7-8-SetupChrony.sh



