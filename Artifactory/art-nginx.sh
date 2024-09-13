curl http://rhvh01.myhost.com/RHEL/Containers/nginx-artifactory-pro_latest.tar.gz -o nginx-artifactory-pro_latest.tar.gz

yum -y install http://satellite.myhost.com/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --activationkey=mykey01 --org=MCI
yum -y install podman
podman load -i nginx-artifactory-pro_latest.tar.gz
mkdir -p /etc/nginx/conf.d
vi /etc/nginx/conf.d/artifactory.conf
groupadd -g 107 nginx
useradd -g 107 -u 104 nginx
chown -R nginx:nginx /etc/nginx
ipa-client-install -p admin -w Iahoora@123 --all-ip-addresses --domain=myhost.com  --realm=MYHOST.COM  --no-ntp --unattended
kinit admin
ipa service-add http/art.myhost.com
mkdir -p /etc/nginx/ssl
chown -R  nginx:nginx /etc/nginx/ssl
chown -R  nginx:nginx /etc/nginx
chmod 777 /etc/nginx/ssl/
chmod 777 /etc/nginx/conf.d/
chmod 777 /etc/nginx/conf.d/artifactory.conf
ipa-getcert request -f /etc/nginx/ssl/art.crt -k /etc/nginx/ssl/art.key -K http/art.myhost.com -D art.myhost.com
firewall-cmd --add-service=http --add-service=https --permanent
podman run --privileged=true --user 107:107 --name artifactory-pro-nginx -d -p 80:80 -p 443:443     -e SKIP_AUTO_UPDATE_CONFIG=true     -v /etc/nginx/ssl:/var/opt/jfrog/nginx/ssl     -v /etc/nginx/conf.d/artifactory.conf:/var/opt/jfrog/nginx/conf.d/artifactory.conf docker.bintray.io/jfrog/nginx-artifactory-pro:latest
