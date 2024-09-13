#podman pull docker.bintray.io/jfrog/artifactory-pro:latest
#podman save docker.bintray.io/jfrog/artifactory-pro:latest -o /mnt/Mount/Containers/artifactory-pro_latest.tar.gz
#podman pull docker.bintray.io/jfrog/nginx-artifactory-pro:latest
curl http://rhvh01.myhost.com/RHEL/Containers/artifactory-pro_latest.tar.gz -o artifactory-pro_latest.tar.g
podman load -i artifactory-pro_latest.tar.gz
setenforce 0

rm -rf /var/opt/jfrog/artifactory
cd /root/
rm -rf tomcat/ pgdata/

groupadd -g 1030 artifactory
useradd -u 1030 -g 1030 artifactory
mkdir -p /var/opt/jfrog/artifactory
semanage fcontext -a -t container_file_t /var/opt/jfrog/artifactory
restorecon -Rv /var/opt/jfrog/artifactory
chown artifactory:artifactory /var/opt/jfrog/artifactory
chmod 777 /var/opt/jfrog/artifactory

mkdir pgdata
podman run --privileged=true  --name postgres -d  -p 5432:5432 -v /root/pgdata:/var/lib/postgresql/data:rw \
-e POSTGRES_PASSWORD=password -e POSTGRES_USER=artifactory -e POSTGRES_DB=artifactory docker.io/library/postgres

podman run --privileged=true   --name artifactory-pro   -d -v /var/opt/jfrog/artifactory:/var/opt/jfrog/artifactory:rw -p 8081:8081 -p 8082:8082 \
-e DB_TYPE=postgresql -e DB_HOST=192.168.1.130 -e DB_PORT=5432 -e DB_USER=artifactory -e DB_PASSWORD=password -e JF_SHARED_DATABASE_DRIVER=org.postgresql.Driver \
-e DB_URL=jdbc:postgresql://192.168.1.130:5432/artifactory -e JF_SHARED_DATABASE_USERNAME=artifactory docker.bintray.io/jfrog/artifactory-pro:latest

yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel firewalld
systemctl enable --now firewalld
firewall-cmd --add-port=8081/tcp --add-port=8082/tcp --permanent
firewall-cmd --reload

#alternatives --config java
dockerID=$(podman ps --format "{{.ID}} {{.Image}} " | grep docker.bintray.io/jfrog/artifactory-pro |  awk '{print $1}')
podman cp ${dockerID}:/opt/jfrog/artifactory/app/artifactory/tomcat tomcat
curl http://rhvh01.myhost.com/RHEL/Files/artifactory-injector-1.1.jar -o artifactory-injector-1.1.jar
java -jar artifactory-injector-1.1.jar
podman cp tomcat ${dockerID}:/opt/jfrog/artifactory/app/artifactory/
podman restart ${dockerID}

#login with user admin and password password and change the password and enter the license key
#then go to the http setting and configure the nginx as a reverse proxy with key and cert location of /etc/nginx/ssl/
#download the configuration file


ldapurl=ldap://idm.myhost.com/dc=myhost,dc=com
userdn= uid={0},cn=users,cn=accounts
searchfilter=uid={0}
searchbase=cn=users,cn=accounts,dc=myhost,dc=com



#docker run  --network mynet --name artifactory -e JF_SHARED_DATABASE_DRIVER=org.postgresql.Driver -e JF_SHARED_DATABASE_URL="jdbc:postgresql://postgres:5432/artifactory" -e JF_SHARED_DATABASE_TYPE=postgresql -e JF_SHARED_DATABASE_HOST=postgres -e JF_SHARED_DATABASE_PORT=5432 -e JF_SHARED_DATABASE_USER=artifactory -e JF_SHARED_DATABASE_PASSWORD=password -p 9081:8081-i -t --rm  docker.bintray.io/jfrog/artifactory-pro:7.10.2
