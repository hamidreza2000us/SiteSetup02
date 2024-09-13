#####################################
#https://hub.docker.com/r/markusmcnugen/openconnect/
#https://www.linuxbabe.com/ubuntu/openconnect-vpn-server-ocserv-ubuntu-20-04-lets-encrypt
#https://dixmata.com/install-openconnect-ubuntu/

hostnamectl set-hostname raido.ir

mkdir /config
mkdir /config/certs
#copy the ssl key and ca here

curl -fsSL https://get.docker.com -o get-docker.sh
bash get-docker.sh

echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/60-custom.conf
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/60-custom.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/60-custom.conf
sysctl -p /etc/sysctl.d/60-custom.conf
 
docker stop $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')
docker rm $(docker ps -a| grep markusmcnugen/openconnect | awk '{print $1}')
#             -e "TUNNEL_ROUTES=192.168.10.0/24"  \
#			 -p 443:4443/udp \
#			 -e "try-mtu-discovery = true" \
docker run --privileged  -d \
             -v /config:/config \
			 -e "DNS_SERVERS=8.8.8.8,8.8.4.4"  \
			 -e "TUNNEL_MODE=all"  \
			 -e "default-domain = raido.ir" \
			 -e "ipv4-network = 10.10.10.0" \
			 -e "tunnel-all-dns = true" \
             -p 8192:4443 \
			 markusmcnugen/openconnect
sleep 2
docker ps
docker exec $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')  apk add libseccomp
docker exec $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')  apk add lz4
docker exec $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')  apk add lz4-dev
#docker exec -ti $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}') ocpasswd -c /config/ocpasswd  user01
docker logs -f $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')
#tcpdump -ni ens192  port 443

#############################
ufw allow 22/tcp
cat >> /etc/ufw/before.rules << EOF

# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 192.168.10.0/24 -o ens192 -j MASQUERADE

# End each table with the 'COMMIT' line or these rules won't be processed
COMMIT
EOF

####################copy these lines after ufw-before-forward icmp lines
# allow forwarding for trusted network
-A ufw-before-forward -s 192.168.10.0/24 -j ACCEPT
-A ufw-before-forward -d 192.168.10.0/24 -j ACCEPT
####################

sudo ufw allow 8192/tcp
sudo ufw allow 8192/udp

sudo ufw enable
systemctl restart ufw
iptables -t nat -L POSTROUTING



###############################
try-mtu-discovery = true
default-domain = raido.ir
ipv4-network = 10.10.10.0
tunnel-all-dns = true

ipv6-network = fda9:4efe:7e3b:03ea::/48
ipv6-subnet-prefix = 64


switch-to-tcp-timeout = 25
persistent-cookies = true
keepalive = 32400

#cookie-timeout = 300
#idle-timeout = 1200
#auth time was the problem
auth-timeout =43200
