#####################################
#https://hub.docker.com/r/markusmcnugen/openconnect/
#https://www.linuxbabe.com/ubuntu/openconnect-vpn-server-ocserv-ubuntu-20-04-lets-encrypt
#https://dixmata.com/install-openconnect-ubuntu/

hostnamectl set-hostname raido.ir

mkdir /config
mkdir /config/certs
#copy the ssl key and ca here
cat > /config/certs/server-key.pem << EOF
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC7A7JkjFROSTWi
L5HC2kaM4jRemEtJ6ZUPjJ5lGYvswFcwdD1dxdbH/xtoJx8KoRrV935bGTOpbFs/
IWmCId9gaO0XgPZT/bU1HurnedWUqeLQa59kBMLSZtY398w8pFwqkxySJTXhkuyt
kIYMxC4Y0wlRqvzohEj/p3NfY+3INQbrI7d+/FU1toPQeyYLnhsorG1cfneaIh1S
b0qNEfLCwgGJAn6Y3imPYlVjwkWf58vv4VZ6ucUL2Q7jA9PU6UYRqjJR2WJ31naY
/WoybqnJNHEB3IuSewHlvnO+usP3s8z/+2EgdCJhVWW6s/bp3bdW/PI1stGJw0zv
elZCtJR7AgMBAAECggEACH3EJXvtqVmk8saVfV3AeE3JB5vYnJ7beBzwEDJsalqC
sEjcLxwi2BUwNGFvr7bdlhDVDuPXtv3xgq33XBjs9d6twonGJXgj4yk9Nzdj8t+9
Ka4eoEGgauyPwMjNNYUCSPiXAoJoA479P2rhe0Y+ZZLSHdWAAuVcFHzmPdLhYrFZ
k9ctkXRvQvJR3/7MT0NmSlX6aXnpz5smSokHyFO7HkowVBRewVK7enLcngmSoh2c
/KRgaEftBOj/XCVdOarucUmPXa0L1y76GLrI/YZrNTulxeVY+EHCsnD58MOutAOh
+P/c0WABolSgl69x863484LESg3Nrh7gfwqmC+sHIQKBgQC78SlZ2rB3FmJ4Xitd
XgjxM/OHoFYtjnlvY5Yh5WKfDHdCc19LsrQ5i7VvvZNAm44StreYrTzaiY1lfGtt
ac89KtPR5iLXDLd47mz87IZzKk3dXxwf2/J2WFWrK0XnMwJEqULwPe54UJ6xTSM+
//JRkGwFZOZHxzcLIeSGwE6sywKBgQD+vItLCIW70g0OQimPUZVCeAo/SHI4/tCi
qU61FZ3/FZaLRUvG13fIvWqBB7Ks8qoKA2QYTuhQf6fkfeehqZNURlxFW6Wqr3IL
UCfWSlhzGhS/COOPy0pDNiT8nlQwCz0iMa8US37H8ksk0KuBW/mCf0VDduNx/kNO
kkTC/HDxEQKBgGorO+7UiWdcr9fLarfdzTNk46e0PbqSh6sTGNahHGs4wY46WpUK
qKDxeVdcQnj25vVPXrvS8VOK7ONtu8odQcMOFIa4eOn+9w5LsinW+8THGyF4/wxI
Vdng4NRHJ8AJorhi3buVYMd604rZRpXqRFsrOLp7W1MlCMUzKkOtE0StAoGAd8tr
Jion2h/6C86JhOC09MFG8GO9c5hBvX0pindUCfW5Cl3YOPZzWm/ZejyIhlTIKlVV
6SiSj+i4p/edyqTYqDU+h0+GJTLEyxUy5s+nsNl/ECe5/JF5pwn7cuFybfWbFk2P
LFgkkxsaw4FuZjM+r2PyyrtKUv1j4btfouLcqkECgYAHJw2q55z5IqQIVIOxv3+K
irEJ2Qh+OXcEknoRpvjrgJUu2OVym7lvgJlJMbsCiT4/ZcmbNzWcuwVLxu07BUkn
ucRs80RBPSK2o0RLmEDayptaIUPh+UjiEguiIO1a4nOMYZJJmlqW43gQdO/nPB9S
+klGww/8+rdYn09RIAinzg==
-----END PRIVATE KEY-----
EOF

cat > /config/certs/server-cert.pem << EOF
-----BEGIN CERTIFICATE-----
MIIFTjCCBDagAwIBAgISA8f6VOdlsq+imJGR/J2mWJ1vMA0GCSqGSIb3DQEBCwUA
MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
EwJSMzAeFw0yMjExMjMxMjU1MjBaFw0yMzAyMjExMjU1MTlaMDAxLjAsBgNVBAMT
JWdyZWF0LWZlcm1hdC4yMTctMTYwLTk2LTU0LnBsZXNrLnBhZ2UwggEiMA0GCSqG
SIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7A7JkjFROSTWiL5HC2kaM4jRemEtJ6ZUP
jJ5lGYvswFcwdD1dxdbH/xtoJx8KoRrV935bGTOpbFs/IWmCId9gaO0XgPZT/bU1
HurnedWUqeLQa59kBMLSZtY398w8pFwqkxySJTXhkuytkIYMxC4Y0wlRqvzohEj/
p3NfY+3INQbrI7d+/FU1toPQeyYLnhsorG1cfneaIh1Sb0qNEfLCwgGJAn6Y3imP
YlVjwkWf58vv4VZ6ucUL2Q7jA9PU6UYRqjJR2WJ31naY/WoybqnJNHEB3IuSewHl
vnO+usP3s8z/+2EgdCJhVWW6s/bp3bdW/PI1stGJw0zvelZCtJR7AgMBAAGjggJe
MIICWjAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUF
BwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFGtfzuItE9CDtzytbn+d8hDQpB4G
MB8GA1UdIwQYMBaAFBQusxe3WFbLrlAJQOYfr52LFMLGMFUGCCsGAQUFBwEBBEkw
RzAhBggrBgEFBQcwAYYVaHR0cDovL3IzLm8ubGVuY3Iub3JnMCIGCCsGAQUFBzAC
hhZodHRwOi8vcjMuaS5sZW5jci5vcmcvMDAGA1UdEQQpMCeCJWdyZWF0LWZlcm1h
dC4yMTctMTYwLTk2LTU0LnBsZXNrLnBhZ2UwTAYDVR0gBEUwQzAIBgZngQwBAgEw
NwYLKwYBBAGC3xMBAQEwKDAmBggrBgEFBQcCARYaaHR0cDovL2Nwcy5sZXRzZW5j
cnlwdC5vcmcwggECBgorBgEEAdZ5AgQCBIHzBIHwAO4AdQC3Pvsk35xNunXyOcW6
WPRsXfxCz3qfNcSeHQmBJe20mQAAAYSkxYnZAAAEAwBGMEQCICdp1bv6gPploq5x
wfkcp0wCSg/lQ3Dr8/DgImKmidD7AiBZyYur5JJ5mF5sGjENb8ryfw4B0A3mtPYn
jKtBIqmWVQB1AK33vvp8/xDIi509nB4+GGq0Zyldz7EMJMqFhjTr3IKKAAABhKTF
igYAAAQDAEYwRAIgJ0Ft3AQVB33cIhcQLKWWttwDNwe2onKvy7qSjNHpASICIEY9
MD4obQ0ge/1zmE3Btqk4Iqez865Mu+WjZIpwihERMA0GCSqGSIb3DQEBCwUAA4IB
AQAxOeLu6/W9s2kfuvNqw5sFcw+czlvtLT7NHPPQ8tcAPRByQmVdgCJCnjfyU98n
OSpXue/zWWN/SoklOELOhCF8vJQYZljbudR/It/0NMyfnLQQhPqzWnYi9qMz4QCU
7J1gzUj4FH7zT1EwDnBz62Yxu6P6f6L+2rYW+kWu7LIl6TAKTdGWING9v87flaYV
FcyU13HRBocDJEn9ijMN5ad2DVoPXQckuvVFV4QKHDBsJ81UcTpeV0U09JR80sxp
W9WWwGPVd6BEKyELzEP6diOhlg6EPF5AhaOOlaze+UMgi/Zozm8fBavl1wrSgOhJ
bIefZDkzr6qyATQhtBbojNlW
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFFjCCAv6gAwIBAgIRAJErCErPDBinU/bWLiWnX1owDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
WhcNMjUwOTE1MTYwMDAwWjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
RW5jcnlwdDELMAkGA1UEAxMCUjMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQC7AhUozPaglNMPEuyNVZLD+ILxmaZ6QoinXSaqtSu5xUyxr45r+XXIo9cP
R5QUVTVXjJ6oojkZ9YI8QqlObvU7wy7bjcCwXPNZOOftz2nwWgsbvsCUJCWH+jdx
sxPnHKzhm+/b5DtFUkWWqcFTzjTIUu61ru2P3mBw4qVUq7ZtDpelQDRrK9O8Zutm
NHz6a4uPVymZ+DAXXbpyb/uBxa3Shlg9F8fnCbvxK/eG3MHacV3URuPMrSXBiLxg
Z3Vms/EY96Jc5lP/Ooi2R6X/ExjqmAl3P51T+c8B5fWmcBcUr2Ok/5mzk53cU6cG
/kiFHaFpriV1uxPMUgP17VGhi9sVAgMBAAGjggEIMIIBBDAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMBIGA1UdEwEB/wQIMAYB
Af8CAQAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1UdIwQYMBaA
FHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcw
AoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzAnBgNVHR8EIDAeMBygGqAYhhZodHRw
Oi8veDEuYy5sZW5jci5vcmcvMCIGA1UdIAQbMBkwCAYGZ4EMAQIBMA0GCysGAQQB
gt8TAQEBMA0GCSqGSIb3DQEBCwUAA4ICAQCFyk5HPqP3hUSFvNVneLKYY611TR6W
PTNlclQtgaDqw+34IL9fzLdwALduO/ZelN7kIJ+m74uyA+eitRY8kc607TkC53wl
ikfmZW4/RvTZ8M6UK+5UzhK8jCdLuMGYL6KvzXGRSgi3yLgjewQtCPkIVz6D2QQz
CkcheAmCJ8MqyJu5zlzyZMjAvnnAT45tRAxekrsu94sQ4egdRCnbWSDtY7kh+BIm
lJNXoB1lBMEKIq4QDUOXoRgffuDghje1WrG9ML+Hbisq/yFOGwXD9RiX8F6sw6W4
avAuvDszue5L3sz85K+EC4Y/wFVDNvZo4TYXao6Z0f+lQKc0t8DQYzk1OXVu8rp2
yJMC6alLbBfODALZvYH7n7do1AZls4I9d1P4jnkDrQoxB3UqQ9hVl3LEKQ73xF1O
yK5GhDDX8oVfGKF5u+decIsH4YaTw7mP3GFxJSqv3+0lUFJoi5Lc5da149p90Ids
hCExroL1+7mryIkXPeFM5TgO9r0rvZaBFOvV2z0gp35Z0+L4WPlbuEjN/lxPFin+
HlUjr8gRsI3qfJOQFy/9rKIJR0Y/8Omwt/8oTWgy1mdeHmmjk7j1nYsvC9JSQ6Zv
MldlTTKB3zhThV1+XWYp6rjd5JW1zbVWEkLNxE7GJThEUG3szgBVGP7pSWTUTsqX
nLRbwHOoq7hHwg==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----

EOF

curl -fsSL https://get.docker.com -o get-docker.sh
bash get-docker.sh

echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/60-custom.conf
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/60-custom.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/60-custom.conf
sysctl -p /etc/sysctl.d/60-custom.conf
 
docker stop $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')
docker rm $(docker ps -a| grep markusmcnugen/openconnect | awk '{print $1}')
#             -e "TUNNEL_ROUTES=192.168.10.0/24"  \
#			 -p 443:4443/udp \
#			 -e "try-mtu-discovery = true" \
docker run --privileged  -d \
             -v /config:/config \
			 -e "DNS_SERVERS=8.8.8.8,8.8.4.4"  \
			 -e "TUNNEL_MODE=all"  \
			 -e "default-domain = great-fermat.217-160-96-54.plesk.page" \
			 -e "ipv4-network = 10.10.10.0" \
			 -e "tunnel-all-dns = true" \
             -p 8192:4443 \
			 markusmcnugen/openconnect
sleep 2
docker ps
docker exec $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')  apk add libseccomp
docker exec $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')  apk add lz4
docker exec $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')  apk add lz4-dev
#docker exec -ti $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}') ocpasswd -c /config/ocpasswd  user01
docker logs -f $(docker ps | grep markusmcnugen/openconnect | awk '{print $1}')
#tcpdump -ni ens192  port 443

#############################
ufw allow 22/tcp
cat >> /etc/ufw/before.rules << EOF

# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 192.168.10.0/24 -o ens192 -j MASQUERADE

# End each table with the 'COMMIT' line or these rules won't be processed
COMMIT
EOF

####################copy these lines after ufw-before-forward icmp lines
# allow forwarding for trusted network
-A ufw-before-forward -s 192.168.10.0/24 -j ACCEPT
-A ufw-before-forward -d 192.168.10.0/24 -j ACCEPT
####################

sudo ufw allow 8192/tcp
sudo ufw allow 8192/udp

sudo ufw enable
systemctl restart ufw
iptables -t nat -L POSTROUTING



###############################
try-mtu-discovery = true
default-domain = raido.ir
ipv4-network = 10.10.10.0
tunnel-all-dns = true

ipv6-network = fda9:4efe:7e3b:03ea::/48
ipv6-subnet-prefix = 64


switch-to-tcp-timeout = 25
persistent-cookies = true
keepalive = 32400

#cookie-timeout = 300
#idle-timeout = 1200
#auth time was the problem
auth-timeout =43200
#oc get pv -A | grep Released | awk '{print $1}' | xargs -I{} oc delete pv {}