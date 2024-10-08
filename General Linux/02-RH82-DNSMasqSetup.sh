#make sure installation DVD is mounted
if [[ $# > 0 ]]
then
  export IDMHOSTNAME=${1}
  export IDMIP=${2}
fi

read -rp "Hostname to set for IDM: ($IDMHOSTNAME): " choice;
       if [ "$choice" != "" ] ; then
               export IDMHOSTNAME="$choice";
       fi

read -rp "IP to use: ($IDMIP): " choice;
       if [ "$choice" != "" ] ; then
               export IDMIP="$choice";
       fi

if [ ! -d /mnt/cdrom ] ; then mkdir /mnt/cdrom ; fi
if [ $(df | grep /mnt/cdrom | grep /dev/sr0 | wc -l) == 0 ]
then
  mount /dev/cdrom /mnt/cdrom
fi

yum -y install augeas dnsmasq

export HOSTNAME=${HOSTNAME:="${hostname}"}
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
cat > /tmp/hostsconfig << EOF
defvar mypath /files/etc/hosts
ins 01 after \$mypath/2/
set \$mypath/01/ipaddr  $IP
set \$mypath/01/canonical $HOSTNAME
save
EOF
augtool -s -f /tmp/hostsconfig

cat > /tmp/hostsconfigIDM << EOF
defvar mypath /files/etc/hosts
ins 01 after \$mypath/2/
set \$mypath/01/ipaddr  $IDMIP
set \$mypath/01/canonical $IDMHOSTNAME
save
EOF
augtool -s -f /tmp/hostsconfigIDM

cat > /tmp/dnsmasqconfig << EOF
defvar mypath /files/etc/dnsmasq.conf
set \$mypath/no-dhcp-interface ens33
set \$mypath/bogus-priv
set \$mypath/domain myhost.com
set \$mypath/expand-hosts
set \$mypath/local /myhost.com/
set \$mypath/domain-needed
set \$mypath/no-resolv
set \$mypath/no-poll
set \$mypath/server[1] 8.8.8.8
set \$mypath/server[2] 4.2.2.4
save
EOF
augtool -s -f /tmp/dnsmasqconfig

if [ ! $( firewall-cmd --query-service=dns)  ]
then
  firewall-cmd --add-service=dns  --permanent
  firewall-cmd --reload
  systemctl restart dnsmasq
fi

if [ ! $(systemctl is-enabled dnsmasq)  ]
then
  systemctl enable dnsmasq
fi