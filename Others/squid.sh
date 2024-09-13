mkdir -p /opt/squid/
cat >> /opt/squid/squid.conf << EOF
acl localnet src 172.16.0.0/12 # RFC1918 possible internal network

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl CONNECT method CONNECT
http_access allow all
http_port 3128
coredump_dir /var/spool/squid
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
refresh_pattern .               0       20%     4320
EOF

podman run --privileged=true --name squid -d -p 80:3128 -e SKIP_AUTO_UPDATE_CONFIG=true -v /opt/squid/squid.conf:/etc/squid/squid.conf docker.io/sameersbn/squid:latest
podman generate systemd squid > /etc/systemd/system/mysquid.service
systemctl daemon-reload
systemctl  enable --now mysquid
systemctl  status mysquid

