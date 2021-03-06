#this script is tested with RH7.8 
#it requires a server with 4 cores and 4 GB of memory
#enough disk space is required
#you should already import the images and also add the repository to install docker
#http://foreman.myhost.com/pub/images/mysql-57-rhel7.tar.gz
#http://foreman.myhost.com/pub/images/quay_v3.3.0.tar.gz
#http://foreman.myhost.com/pub/images/redis-32-rhel7.tar.gz

#export IDMIP=192.168.1.112
#export IDMPASS="Iahoora@123"
export QuayIP=172.20.29.133
#export VPNIP=192.168.1.155
ansible-playbook -i ~/.inventory 06-FromTemplate-WithIPDisk-RH8.yml -e VMName=quay -e VMMemory=8GiB -e VMCore=8  \
-e HostName=quay.myhost.com -e VMTempate=Template8.3 -e VMDiskSize=100GiB  -e VMISO=rhel-8.3-x86_64-dvd.iso -e VMIP=${QuayIP}
sed -i "/${QuayIP}/d" /root/.ssh/known_hosts
ssh -o StrictHostKeyChecking=no ${QuayIP} /bin/bash << 'EOF2'
export IDMIP=172.20.29.130
export IDMPASS="Iahoora@123"
export QuayIP=172.20.29.133
export VPNIP=172.20.29.158
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

echo ${IDMPASS} | kinit admin; ipa dnsrecord-add myhost.com. quay --a-ip-address=${QuayIP}  --a-create-reverse 

yum install -y docker mariadb telnet firewalld wget
systemctl start firewalld
con=$( nmcli -g UUID,type con sh --active | grep ethernet | awk -F: '{print $1}' | head -n1)
nmcli con mod "$con"  ipv4.dns ${IDMIP} ipv4.gateway ${VPNIP} 
nmcli con up $con

systemctl enable podman --now

firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --add-service=mysql --permanent
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
wget http://rhvh01.myhost.com/RHEL/Containers/mysql-57-rhel7.tar.gz
wget http://rhvh01.myhost.com/RHEL/Containers/quay_v3.3.0.tar.gz
wget http://rhvh01.myhost.com/RHEL/Containers/redis-32-rhel7.tar.gz

docker load -i mysql-57-rhel7.tar.gz
docker load -i redis-32-rhel7.tar.gz
docker load -i quay_v3.3.0.tar.gz

mkdir -p /var/lib/mysql
chmod 777 /var/lib/mysql
export MYSQL_CONTAINER_NAME=mysql
export MYSQL_DATABASE=enterpriseregistrydb
export MYSQL_PASSWORD=ahoora
export MYSQL_USER=quayuser
export MYSQL_ROOT_PASSWORD=ahoora
docker run --detach --restart=always --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} --env MYSQL_USER=${MYSQL_USER}  \
--env MYSQL_PASSWORD=${MYSQL_PASSWORD} --env MYSQL_DATABASE=${MYSQL_DATABASE} --name ${MYSQL_CONTAINER_NAME} --privileged=true \
--publish 3306:3306  -v /var/lib/mysql:/var/lib/mysql/data:Z  quay.myhost.com/admin/mysql-57-rhel7
####note the permission required for /var/lib/mysql ????
semanage fcontext -a -t mysqld_db_t "/var/lib/mysql(/.*)?"
restorecon -Rv /var/lib/mysql
mkdir -p /var/lib/redis
docker run -d --restart=always -p 6379:6379  --privileged=true  -v /var/lib/redis:/var/lib/redis/data:Z \
quay.myhost.com/admin/redis-32-rhel7

openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem -subj \
"/C=GR/ST=Frankfurt/L=Frankfurt/O=SanCluster/CN=quay.myhost.com"

IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
hostname=$(hostname -f)

cat >  openssl.cnf << EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${hostname}
IP.1 = ${IP}
EOF

openssl genrsa -out ssl.key 2048
openssl req -new -key ssl.key -out ssl.csr -subj "/CN=quay-enterprise" -config openssl.cnf
openssl x509 -req -in ssl.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ssl.cert -days 356 -extensions v3_req -extfile openssl.cnf

mkdir -p /etc/docker/certs.d/quay.myhost.com/ #change to the hostname
cp rootCA.pem /etc/docker/certs.d/quay.myhost.com/ca.crt #change to the hostname
update-ca-trust
mkdir -p /var/quay/config
chmod 777 /var/quay/config
mkdir -p /var/quay/storage
chmod 777 /var/quay/storage
docker run --privileged=true -p 8443:8443 -d quay.myhost.com/admin/quay:v3.3.0 config ${MYSQL_PASSWORD} quay.myhost.com/admin/quay:v3.3.0
cp ssl.cert ssl.crt




echo "###########################################"
echo "Download the ssl.key and ssl.cert to your desktop"
echo "Pleae open a web browser with this address:"
echo "https://$(hostname -f):8443"
echo "Username is: quayconfig"
echo "Password is: ${MYSQL_PASSWORD}"
echo "###########################################"
echo -n " "
echo "###########################################"
echo "Click on start new registory setup"
echo "Database type is Mysql"
echo "Database Server: $(hostname -f)"
echo "Username: ${MYSQL_USER}"
echo "Pasword: ${MYSQL_PASSWORD}"
echo "Databse Name: ${MYSQL_DATABASE}"
echo "###########################################"
echo "Enter your desired credentials"
echo "###########################################"
echo "Server Hostname: $(hostname -f)"
echo "TLS: Red Hat Quay handles TLS"
echo "Certificate: ssl.cert"
echo "Private Key: ssl.key"
echo "Redis Hostname:  $(hostname -f)"
echo "Save Configuration Changes"
echo "Download Configuration from the browser and upload to the linux server"
echo "###########################################"
echo -n " "
echo -n " "
echo "###########################################"
echo "Then enter the following commands manually"
echo "cp quay-config.tar.gz /var/quay/config/"
echo "cd /var/quay/config/"
echo "tar xvf quay-config.tar.gz"
echo "docker run --restart=always -p 443:8443 -p 80:8080 --sysctl net.core.somaxconn=4096 --privileged=true \
-v /var/quay/config:/conf/stack:Z -v /var/quay/storage:/datastorage:Z -d quay.myhost.com/admin/quay:v3.3.0"
echo "###########################################"
echo "login to you quay server with address below:"
echo "https://$(hostname -f)"
EOF2

#docker run --restart=always -p 443:8443 -p 80:8080 --sysctl net.core.somaxconn=4096 --privileged=true \
#-v /var/quay/config:/conf/stack:Z -v /var/quay/storage:/datastorage:Z -d quay.myhost.com/admin/quay:v3.3.0

#docker run -d --name mirroring-worker2 -v /mnt/quay/config:/conf/stack -v \
#/root/ca.crt:/etc/pki/ca-trust/source/anchors/ca.crt quay.myhost.com/admin/quay:v3.3.0 repomirror

#for i in $(podman ps -a | awk '{print $1}' | tail -n +2 ) ; do podman rm $i ; done
