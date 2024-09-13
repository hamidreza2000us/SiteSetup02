user=user06
host=ipaclient12
mount -o loop,ro /dev/cdrom /mnt/cdrom/
yum install -y ipa-client bind-utils  
ipa-client-install -p admin -w Iahoora@123 --realm=MYHOST.COM --mkhomedir  -U
echo "Iahoora@123" | kinit admin
mkdir NSSDB
certutil -N -d NSSDB/
ipa user-add ${user} --first ${user} --last user
certutil -R -d NSSDB/ -k rsa -g 4096 -a -s "CN=${user},O=MYHOST.COM" -o ${user}.csr
ipa cert-request --profile-id=IECUserRoles --principal=${user}@MYHOST.COM --certificate-out=${user}.pem ${user}.csr
certutil -A -d NSSDB/ -i ${user}.pem -t "P,," -n ${user}
pk12util -d NSSDB/ -n ${user} -o ${user}.p12
openssl pkcs12 -in ${user}.p12 -nodes -nocerts -out ${user}.key
openssl pkcs12 -in ${user}.p12 -nodes -clcerts -out ${user}.cert
ipa service-add mysql/${host}.myhost.com
mkdir /etc/mysql-certs
semanage fcontext -a -t cert_t "/etc/mysql-certs(/.*)?"
restorecon -Rv /etc/mysql-certs/
chown mysql /etc/mysql-certs/
ipa-getcert request -k /etc/mysql-certs/mysql.key -f /etc/mysql-certs/mysql.pem -K mysql/${host}.myhost.com -D ${host}.myhost.com
yum install -y mariadb-server
cat >> /etc/my.cnf << EOF
[mariadb]
ssl-key=/etc/mysql-certs/mysql.key
ssl-cert=/etc/mysql-certs/mysql.pem
ssl-ca=/etc/mysql-certs/ca.crt
EOF
cp /etc/ipa/ca.crt /etc/mysql-certs/
chown -R mysql /etc/mysql-certs/
systemctl enable mariadb.service
systemctl start mariadb.service
mysql_secure_installation
mysql -u root -pahoora
MariaDB [(none)]> create database top_secret;
MariaDB [(none)]> create user ${user}@localhost require issuer "/O=MYHOST.COM/CN=Certificate Authority" and subject  "/O=MYHOST.COM/CN=${user}" ;
MariaDB [(none)]> grant all privileges on top_secret.* to ${user}@localhost; 
mysql -u ${user} --ssl-key ${user}.key --ssl-cert ${user}.cert 

