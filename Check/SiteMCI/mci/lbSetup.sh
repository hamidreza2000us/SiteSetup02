#podman installation via https://www.haproxy.com/documentation/hapee/2-1r1/installation/docker/
#podman config via https://access.redhat.com/articles/5127211
#podman source via https://catalog.redhat.com/software/containers/haproxytech/haproxy/594d19264b339a4816dc3dfa?container-tabs=overview&gti-tabs=get-the-source

#subscription-manager register --org="MCI" --activationkey="kceph04"
yum -y install podman
Domain=idm.mci.ir
SatHost=satellite
wget http://${SatHost}.${Domain}/pub/RHEL/Containers/haproxy.tar
#sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
#setenforce 0
#reboot is required

#podman login registry.connect.redhat.com
#podman pull registry.connect.redhat.com/haproxytech/haproxy
podman load -i haproxy.tar

export RGW1=10.19.75.10:8080
export RGW2=10.19.75.11:8080
export RGW3=10.19.75.12:8080

mkdir /haproxy
echo "Iahoora@123" | kinit admin
ipa-getcert request -f /etc/pki/tls/certs/$(hostname).crt -k /etc/pki/tls/private/$(hostname).key -K HTTP/$(hostname) -D $(hostname)
sleep 10
cat  /etc/pki/tls/certs/$(hostname).crt /etc/pki/tls/private/$(hostname).key | sudo tee /haproxy/$(hostname -f).pem
sleep 5

cd /haproxy
cat > /haproxy/haproxy.cfg << EOF
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   https://www.haproxy.org/download/1.8/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    #chroot      /var/lib/haproxy
    pidfile     /var/lib/haproxy/haproxy.pid
    maxconn     4000
    #user        haproxy
    #group       haproxy
    #daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

    # utilize system-wide crypto-policies
    #ssl-default-bind-ciphers PROFILE=SYSTEM
    #ssl-default-server-ciphers PROFILE=SYSTEM

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
#Enable HAProxy stats
listen stats
    mode http
    bind :9000
    stats uri /stats
    stats refresh 10000ms

frontend http_web 
    mode http
	bind :8080
    default_backend rgw

frontend https_web
    bind :8443 ssl crt /etc/haproxy/$(hostname -f).pem
    default_backend rgw
	
#---------------------------------------------------------------------
# static backend
#---------------------------------------------------------------------

backend rgw
	balance roundrobin
	mode http
	server RGW1 ${RGW1} check
	server RGW2 ${RGW2} check
	server RGW3 ${RGW3} check

EOF

semanage fcontext -a -t container_file_t  '/haproxy(/.*)?'
restorecon -Rv /haproxy
chmod 655 /haproxy
chmod 644 /haproxy/haproxy.cfg

podman run \
    --name hapee \
    -d \
    -p 80:8080 \
    -p 443:8443 \
    -p 8199:8199 \
    -v /haproxy:/etc/haproxy  \
    --restart=always \
    --privileged=true \
    registry.connect.redhat.com/haproxytech/haproxy:latest
	
firewall-cmd --add-service=http --add-service=https --permanent
firewall-cmd --add-port=9000/tcp --permanent
firewall-cmd --reload
