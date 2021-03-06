#podman installation via https://www.haproxy.com/documentation/hapee/2-1r1/installation/docker/
#podman config via https://access.redhat.com/articles/5127211
#podman source via https://catalog.redhat.com/software/containers/haproxytech/haproxy/594d19264b339a4816dc3dfa?container-tabs=overview&gti-tabs=get-the-source
IDMIP=192.168.1.112
GWIP=192.168.1.155
WebIP=192.168.1.152

export LOADBALANCER_IP=192.168.1.230
export MASTER0_IP=192.168.1.231
export MASTER1_IP=192.168.1.232
export MASTER2_IP=192.168.1.233
export COMPUTE0_IP=192.168.1.234
export COMPUTE1_IP=192.168.1.235
export BOOTSTRAP_IP=192.168.1.236

hostnamectl set-hostname lb.myhost.com
nmcli con mod System\ eth0 con-name fixed ipv4.method static ipv4.gateway ${GWIP} ipv4.dns ${IDMIP} ipv4.addresses ${LOADBALANCER_IP}/24 
nmcli con up fixed

mount -o loop,ro /dev/cdrom /mnt/cdrom
yum -y install podman bind-utils firewalld telnet wget
systemctl enable firewalld
systemctl start firewalld

#sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
#setenforce 0
#reboot is required

#podman login registry.connect.redhat.com
#podman pull registry.connect.redhat.com/haproxytech/haproxy
wget http://${WebIP}/RHEL/Containers/haproxy.tar
podman load -i haproxy.tar



	
mkdir /haproxy
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

frontend api
    mode tcp
    bind :6443
    default_backend controlplaneapi

frontend machineconfig
    mode tcp
    bind :22623
    default_backend controlplanemc

frontend tlsrouter
    mode tcp
    bind :8443
    default_backend secure

frontend insecurerouter
    mode tcp
    bind :8080
    default_backend insecure

#---------------------------------------------------------------------
# static backend
#---------------------------------------------------------------------

backend controlplaneapi
    mode tcp
    balance source
    server bootstrap ${BOOTSTRAP_IP}:6443 check
    server master0 ${MASTER0_IP}:6443 check
    server master1 ${MASTER1_IP}:6443 check
    server master2 ${MASTER2_IP}:6443 check


backend controlplanemc
    mode tcp
    balance source
    server bootstrap ${BOOTSTRAP_IP}:22623 check
    server master0 ${MASTER0_IP}:22623 check
    server master1 ${MASTER1_IP}:22623 check
    server master2 ${MASTER2_IP}:22623 check

backend secure
    mode tcp
    balance source
    server compute0 ${COMPUTE0_IP}:443 check
    server compute1 ${COMPUTE1_IP}:443 check

backend insecure
    mode tcp
    balance source
    server worker0 ${COMPUTE0_IP}:80 check
    server worker1 ${COMPUTE1_IP}:80 check
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
    -p 9000:9000 \
    -p 6443:6443 \
    -p 22623:22623 \
    -v /haproxy:/etc/haproxy  \
    --restart=always \
    --privileged=true \
    registry.connect.redhat.com/haproxytech/haproxy
	
firewall-cmd --add-service=http --add-service=https --permanent
firewall-cmd --add-port=6443/tcp --add-port=22623/tcp  --add-port=9000/tcp --permanent
firewall-cmd --reload
