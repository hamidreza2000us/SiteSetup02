#put in /etc/bashrc
export JFROG_HOME=/opt/jfrog
yum -y localinstall jfrog-artifactory-pro-7.15.3.rpm
 systemctl disable artifactory
 
cat <<EOF | sudo tee /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.4/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

 yum -y install mariadb-server mariadb-server-utils
 systemctl enable --now mariadb
mysql_secure_installation


mysql -uroot -pahoora
CREATE DATABASE artdb CHARACTER SET utf8 COLLATE utf8_bin;
GRANT ALL on artdb.* TO 'artifactory'@'localhost' IDENTIFIED BY 'ahoora';
flush privileges;

source /etc/bashrc
cp mariadb-java-client-2.7.2.jar $JFROG_HOME/artifactory/var/bootstrap/artifactory/tomcat/lib

/etc/my.cnf
[MariaDBd]
max_allowed_packet=8M
innodb_file_per_table
innodb_buffer_pool_size=1536M
tmp_table_size=512M
max_heap_table_size=512M
innodb_log_file_size=256M
innodb_log_buffer_size=4M



/opt/jfrog/artifactory/var/etc/system.yaml
	database:
      type: mariadb
      driver: org.mariadb.jdbc.Driver
      url: jdbc:mariadb://localhost:3306/artdb?characterEncoding=UTF-8&elideSetAutoCommits=true&useSSL=false&useMysqlMetadata=true
      username: artifactory
      password: ahoora

chown artifactory:artifactory $JFROG_HOME/artifactory/var/bootstrap/artifactory/tomcat/lib/mariadb-java-client-2.7.2.jar
chmod +x $JFROG_HOME/artifactory/var/bootstrap/artifactory/tomcat/lib/mariadb-java-client-2.7.2.jar

yum instlal -y vim wget unzip
yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel
alternatives --config java 


to crack java -jar artifactory-injector-1.1.jar
#select 2 for injector
#use this as directory /opt/jfrog/artifactory/app/artifactory/tomcat/
#select 1 to generate license
eyJhcnRpZmFjdG9yeSI6eyJpZCI6IiIsIm93bmVyIjoicjRwMyIsInZhbGlkRnJvbSI6MTYxNDU5ODk3NDE0NiwiZXhwaXJlcyI6MTY0NjExNjk3NDEwMSwidHlwZSI6IkVOVEVSUFJJU0VfUExVUyIsInRyaWFsIjpmYWxzZSwicHJvcGVydGllcyI6e319fQ==
systemctl enable --now artifactory


tail -F $JFROG_HOME/artifactory/var/log/console.log
#default url is URL:8081 username admin and password password

  10  mkdir certs
   11  yum install -y nginx
   12  cd /etc/nginx/
   13  mkdir ssl
   14  chmod 600 ssl
   15  cd ssl
   16  openssl genrsa -out rootCA.key 2048
   17  openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem -subj "/C=GR/ST=Frankfurt/L=Frankfurt/O=SanCluster/CN=art.myhost.com"
   18  ls
   19  pwd
   20  vi /etc/nginx/nginx.conf
   21  vi /etc/nginx/conf.d/art.conf
   22  systemctl restart nginx
   23  systemctl status nginx




Join Active:
Search Filter: sAMAccountName={0}
ManagerDN:CN=art,OU=MSA,OU=Services,OU=Behsa-OU,DC=Behsacorp,DC=com

