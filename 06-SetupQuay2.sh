#yum install -y mariadb telnet firewalld wget
IDMPASS=Iahoora@123
echo ${IDMPASS} | kinit admin;
yum install -y  podman firewalld wget
systemctl enable --now firewalld podman

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

podman load -i mysql-57-rhel7.tar.gz
podman load -i redis-32-rhel7.tar.gz
podman load -i quay_v3.3.0.tar.gz

mkdir -p /var/lib/mysql
chmod 777 /var/lib/mysql
export MYSQL_CONTAINER_NAME=mysql
export MYSQL_DATABASE=enterpriseregistrydb
export MYSQL_PASSWORD=ahoora
export MYSQL_USER=quayuser
export MYSQL_ROOT_PASSWORD=ahoora
podman run --detach --restart=always --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} --env MYSQL_USER=${MYSQL_USER}  \
--env MYSQL_PASSWORD=${MYSQL_PASSWORD} --env MYSQL_DATABASE=${MYSQL_DATABASE} --name ${MYSQL_CONTAINER_NAME} --privileged=true \
--publish 3306:3306  -v /var/lib/mysql:/var/lib/mysql/data:Z  quay.myhost.com/admin/mysql-57-rhel7

semanage fcontext -a -t mysqld_db_t "/var/lib/mysql(/.*)?"
restorecon -Rv /var/lib/mysql
mkdir -p /var/lib/redis
podman run -d --restart=always -p 6379:6379  --privileged=true  -v /var/lib/redis:/var/lib/redis/data:Z \
quay.myhost.com/admin/redis-32-rhel7

mkdir -p /var/quay/config
chmod 777 /var/quay/config
mkdir -p /var/quay/storage
chmod 777 /var/quay/storage

ipa service-add HTTP/$(hostname -f)
ipa-getcert request -f /tmp/ssl.crt -k /tmp/ssl.key -K  HTTP/$(hostname -f) -D $(hostname -f)
sleep 5

cp /tmp/ssl.crt /var/quay/config/
cp /tmp/ssl.key /var/quay/config/

podman run --privileged=true -p 8443:8443 -d quay.myhost.com/admin/quay:v3.3.0 config ${MYSQL_PASSWORD} quay.myhost.com/admin/quay:v3.3.0

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
echo "cp /tmp/quay-config.tar.gz /var/quay/config/"
echo "cd /var/quay/config/"
echo "tar xvf quay-config.tar.gz"
echo "podman run --restart=always -p 443:8443 -p 80:8080 --sysctl net.core.somaxconn=4096 --privileged=true \
 -v /var/quay/config:/conf/stack:Z -v /var/quay/storage:/datastorage:Z -d quay.myhost.com/admin/quay:v3.3.0"
echo "###########################################"
echo "login to you quay server with address below:"
echo "https://$(hostname -f)"
























