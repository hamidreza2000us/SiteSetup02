curl ipinfo.io
echo "metadata_expire=24h" >> /etc/yum.conf
#0 3 * * * /usr/bin/yum makecache > /dev/null 2>&1
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo subscription-manager register --username=hamidreza2000us@yahoo.com --password=Iahoora@1234
sudo  yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct telnet podman podman-docker jq glibc podman-compose 

yum install -y 
sudo yum install -y telnet
sudo yum -y install podman podman-docker jq



cat <<EOF > pullsecret
{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfYjdjNTNlMzE1MTk5NDcyMDhkZTU4YzE2MGYwYTZlMjE6UFI4T0U4UTY1SVg3SUNBQVVGVEE0VUgwQ0xGU1hJTExOOTYySUlPNUhUWDNIRFlKVlNFQ09XNVFCVlZBMFFOUQ==","email":"hamidreza2000us@yahoo.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfYjdjNTNlMzE1MTk5NDcyMDhkZTU4YzE2MGYwYTZlMjE6UFI4T0U4UTY1SVg3SUNBQVVGVEE0VUgwQ0xGU1hJTExOOTYySUlPNUhUWDNIRFlKVlNFQ09XNVFCVlZBMFFOUQ==","email":"hamidreza2000us@yahoo.com"},"registry.connect.redhat.com":{"auth":"fHVoYy1wb29sLTNhNWE3OWJmLTkxYjctNDY5Yy1iNTExLTQwYTk0ZmRlZTUyMjpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSTFOelJtTURBMk5UZzNNV1UwWlRrM1ltVm1NMlJsTWpsaE4yUmtPR1prTmlKOS5QdndIN3JVVlpPdFN3dF8weGljSFNVLUlXSTFSU0JsT3g3U2MyQ1owcDBfZWN6RFd1cUwybjBST2Z1Ml9GTkRRZ0hkbEFkRkhVTkhxd1VyTkRfN0ZVUEtKRnRZUmlsVkNxOURmX2stV3k2bUZKVmpvWE54RGdxZEpnR3Q3dmU1VFFEYkFpOGN0Q0h6TEpaZG5hbllxQWU0OG9VTDdVX2IzTUtpNVZnWGo5dV9LTU0xdl9YVjhHUUxPUi1vNFVETDhBV0VEQy1vWVczRXNIa3hFa2NRMjVqcG9CQ0M1WHZsc1VaRTV3VVctUElocXQ5ZXhpdUZiUEFJRU5UTDc3R2s3RGNCLVB2NndNZGFOUkt1a3RZS2hVTWd5OUFwTUdocGxiWUJiLUNnazR5OU80WVdEYnRqWjRBYzk5NmV3djFVbTlUZmNKdVNaN0QxUk9rZlhOWUV5bldlNm5WRGxILUNNMml5WVI2a040elRrT0czbmpCNlp5azlZc2JYYjZ6VmpqN0V1bkxCZHBXZHgyaXNYc29DVFdLQTY5dC1VVDRRbkcxZ2FNVW0zajVrdXZETW1QS21vcUl5R1Rzd004SFdWMlMzaWNLdTJZOWs4b1hHMVBzbTJTUVdNY050RExWcnR5dW80WTBXd0Vrdnl1azB2anRvQ3lwVjhfb3Njajc3RTVtTVNYajRLYllabWhIWnJZV1ZtbHg1dWRqM2QyTk00M2JVaEpOM2FDX240SzkwSHE3NmNTdjFMd0NwU3lEb0V1cjFyRDhnVUpRVEkta2pNRFNkRmlTbFhxcnA0aG9CcHJiX3ZmMzlrUE5Ic3kxLUlNaU40TXJ4Z05OdjhQNnhwWnIzZjd0bzFGNjRxb0kyc0J3bXFROV9kUXo2NllyZGt3am5oVmZUN2FLSQ==","email":"hamidreza2000us@yahoo.com"},"registry.redhat.io":{"auth":"fHVoYy1wb29sLTNhNWE3OWJmLTkxYjctNDY5Yy1iNTExLTQwYTk0ZmRlZTUyMjpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSTFOelJtTURBMk5UZzNNV1UwWlRrM1ltVm1NMlJsTWpsaE4yUmtPR1prTmlKOS5QdndIN3JVVlpPdFN3dF8weGljSFNVLUlXSTFSU0JsT3g3U2MyQ1owcDBfZWN6RFd1cUwybjBST2Z1Ml9GTkRRZ0hkbEFkRkhVTkhxd1VyTkRfN0ZVUEtKRnRZUmlsVkNxOURmX2stV3k2bUZKVmpvWE54RGdxZEpnR3Q3dmU1VFFEYkFpOGN0Q0h6TEpaZG5hbllxQWU0OG9VTDdVX2IzTUtpNVZnWGo5dV9LTU0xdl9YVjhHUUxPUi1vNFVETDhBV0VEQy1vWVczRXNIa3hFa2NRMjVqcG9CQ0M1WHZsc1VaRTV3VVctUElocXQ5ZXhpdUZiUEFJRU5UTDc3R2s3RGNCLVB2NndNZGFOUkt1a3RZS2hVTWd5OUFwTUdocGxiWUJiLUNnazR5OU80WVdEYnRqWjRBYzk5NmV3djFVbTlUZmNKdVNaN0QxUk9rZlhOWUV5bldlNm5WRGxILUNNMml5WVI2a040elRrT0czbmpCNlp5azlZc2JYYjZ6VmpqN0V1bkxCZHBXZHgyaXNYc29DVFdLQTY5dC1VVDRRbkcxZ2FNVW0zajVrdXZETW1QS21vcUl5R1Rzd004SFdWMlMzaWNLdTJZOWs4b1hHMVBzbTJTUVdNY050RExWcnR5dW80WTBXd0Vrdnl1azB2anRvQ3lwVjhfb3Njajc3RTVtTVNYajRLYllabWhIWnJZV1ZtbHg1dWRqM2QyTk00M2JVaEpOM2FDX240SzkwSHE3NmNTdjFMd0NwU3lEb0V1cjFyRDhnVUpRVEkta2pNRFNkRmlTbFhxcnA0aG9CcHJiX3ZmMzlrUE5Ic3kxLUlNaU40TXJ4Z05OdjhQNnhwWnIzZjd0bzFGNjRxb0kyc0J3bXFROV9kUXo2NllyZGt3am5oVmZUN2FLSQ==","email":"hamidreza2000us@yahoo.com"}}}
EOF

#wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.16.6/openshift-client-linux-amd64-rhel8.tar.gz
#tar -xvf openshift-client-linux-amd64-rhel8.tar.gz

wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz
tar -xvf openshift-client-linux.tar.gz
sudo mv oc /usr/bin/
sudo mv kubectl /usr/bin/

oc completion bash > /tmp/oc.sh ;
chmod +x /tmp/oc.sh ;
sudo mv /tmp/oc.sh /etc/bash_completion.d/ ;
echo 'source /etc/bash_completion.d/oc.sh' >> ~/.bashrc ;
source /etc/bash_completion.d/oc.sh ;


#wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz
#tar -xvf openshift-install-linux.tar.gz
#sudo mv openshift-install /usr/bin/

#oc adm release extract -a ${LOCAL_SECRET_JSON} --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"


sudo sysctl -w net.ipv4.conf.all.accept_redirects=1
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=0
sudo sysctl -p

#####################################################
mkdir dns 
cd dns

cat <<EOF >  podman-compose.yml
version: '3.8'

services:
  dns_dhcp:
    image: jpillora/dnsmasq
    container_name: dns_dhcp
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - DNS_FORWARDER=8.8.8.8
    volumes:
      - ./dnsmasq.conf:/etc/dnsmasq.conf:ro
    restart: always
EOF

cat <<EOF >  dnsmasq.conf
# Increase the maximum number of concurrent DNS queries
dns-forward-max=500

# Other dnsmasq configurations
cache-size=1000
log-queries
log-dhcp
# DNS Configuration
address=/api.myocp.behsacorp.com/172.18.109.61
address=/api-int.myocp.behsacorp.com/172.18.109.61
address=/.apps.myocp.behsacorp.com/172.18.109.61
address=/vctest.behsacorp.com/172.18.64.50

# Optional: Forward all other DNS queries to an upstream DNS server
server=8.8.8.8  # Google DNS, you can change this to any other DNS server

# DHCP Configuration
dhcp-range=172.18.109.72,172.18.109.75,24h  # IP range for DHCP
dhcp-option=3,172.18.109.254  # Gateway
dhcp-option=6,172.18.109.61   # DNS Server (IP of the dnsmasq server)
EOF

sudo podman-compose up -d


sudo firewall-cmd --permanent --add-port=53/udp
sudo firewall-cmd --permanent --add-port=67/udp
sudo firewall-cmd --permanent --add-port=68/udp
sudo firewall-cmd --reload

cd ..


#####################################################
sudo nmcli connection modify ens192  +ipv4.addresses 172.18.109.77/24
sudo nmcli connection modify ens192  +ipv4.addresses 172.18.109.78/24
sudo nmcli con reload
sudo nmcli con up ens192
#####################################################
mkdir haproxy
cd haproxy

cat <<EOF >  haproxy.cfg
global
    log stdout format raw local0
    maxconn 4096
    user haproxy
    group haproxy

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    retries 3
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend api_front
    bind *:6443
    default_backend masters_6443

frontend api_front_22623
    bind *:22623
    default_backend masters_22623

backend masters_6443
    balance roundrobin
    server master-0 172.18.109.72:6443 check
    server master-1 172.18.109.73:6443 check
    server master-2 172.18.109.74:6443 check
    server master-3 172.18.109.75:6443 check

backend masters_22623
    balance roundrobin
    server master-0 172.18.109.72:22623 check
    server master-1 172.18.109.73:22623 check
    server master-2 172.18.109.74:22623 check
    server master-3 172.18.109.75:22623 check

frontend ingress_front
    bind *:80
    default_backend workers_http

    bind *:443
    default_backend workers_https

backend workers_http
    balance roundrobin
    server worker-0 172.18.109.72:80 check
    server worker-1 172.18.109.73:80 check
    server worker-2 172.18.109.74:80 check
    server worker-3 172.18.109.75:80 check

backend workers_https
    balance roundrobin
    server worker-0 172.18.109.72:443 check
    server worker-1 172.18.109.73:443 check
    server worker-2 172.18.109.74:443 check
    server worker-3 172.18.109.75:443 check

EOF

cat <<EOF >  podman-compose.yaml
version: '3'
services:
  haproxy:
    image: docker.io/library/haproxy:latest
    container_name: haproxy-openshift
    restart: always
    ports:
      - "6443:6443"
      - "80:80"
      - "443:443"
      - "22623:22623"

    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    networks:
      - haproxy-net
    cap_add:
      - NET_BIND_SERVICE
networks:
  haproxy-net:
    driver: bridge
EOF


sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=22623/tcp
sudo firewall-cmd --reload

sudo podman-compose up -d
cd ..

#####################################################

#############################################################
sed -i '/^platform:/i\
imageContentSources:\n\
- mirrors:\n\
  - 127.0.0.1:5000/ocp4/openshift4\n\
  source: quay.io/openshift-release-dev/ocp-release\n\
\n\
registrySources:\n\
  insecureRegistries:\n\
  - 127.0.0.1:5000\n' install-config.yaml


###########################################################

#####################################################

#sudo tcpdump -ni any port 67
#podman logs dns_dhcp

mkdir openshift-install
cd openshift-install


sudo curl -k -O https://vctest.behsacorp.com/certs/download.zip
#AdminVM@20242024#
unzip download.zip
sudo cp certs/lin/deb51e07.0 /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
curl https://vctest.behsacorp.com

#openshift-install create install-config
openshift-install create install-config --dir=./
# vctest.behsacorp.com
# administrator@vcenter.local
#AdminVM@20242024#
#172.18.109.77
#172.18.109.78
#behsacorp.com
#myocp

#CERT_CONTENT=$(cat certs/lin/deb51e07.0 | fold -w 64 | sed 's/^/  /')
#TRUST_BUNDLE="additionalTrustBundle: |\n${CERT_CONTENT}"
#awk -v trust_bundle="$TRUST_BUNDLE" '!seen && /^platform:/ {print trust_bundle; seen=1}1' install-config.yaml > temp.yaml && mv temp.yaml install-config.yaml

CERT_CONTENT=$(cat /opt/quay/certs/ssl.cert | fold -w 64 | sed 's/^/  /')
TRUST_BUNDLE="additionalTrustBundle: |\n${CERT_CONTENT}"
awk -v trust_bundle="$TRUST_BUNDLE" '!seen && /^platform:/ {print trust_bundle; seen=1}1' install-config.yaml > temp.yaml && mv temp.yaml install-config.yaml


#ssh-keygen -t rsa -b 4096 -f /home/hamid/.ssh/id_rsa -N ''
sshkey=$(cat /home/hamid/.ssh/id_rsa.pub)
sed -i  "/^metadata:/i\sshKey: | \n   $sshkey \n" install-config.yaml


#sed -i '/^platform:/i\
#imageContentSources:\n\
#- mirrors:\n\
#  - 172.18.109.61:8443/ocp4/openshift4\n\
#  source: quay.io/openshift-release-dev/ocp-release\n\
#\n\
#registrySources:\n\
#  insecureRegistries:\n\
#  - 172.18.109.61:8443\n' install-config.yaml

#vi openshift-install/install-config.yaml
#Always

sed -i '/^platform:/i\
ImageDigestSources:\
- mirrors:\
  - 172.18.109.61:8443/ocp4/openshift4\
  source: quay.io/openshift-release-dev/ocp-release\n' install-config.yaml

#ImageDigestSources:
imageContentSources:
- mirrors:
  - 172.18.109.61:8443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - 172.18.109.61:8443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  

#export GOVC_TIMEOUT=60m

cd ..
rm -rf openshift-install
mkdir openshift-install
cd openshift-install/
cp ../install-config.yaml.back13 .
mv install-config.yaml.back12 install-config.yaml

openshift-install create cluster --dir=./
#firewall disabled or configured
#ssh -i .ssh/id_rsa core@172.18.109.75

#vctest.behsacorp.com.myocp.behsacorp.com