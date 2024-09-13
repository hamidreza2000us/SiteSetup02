
###
#This script is to configure RHEL8 for minimal GUI installation

cat << EOF > /etc/yum.repos.d/cd.repo
[AppStream]
name=AppStream
baseurl=file:///mnt/cdrom/AppStream
gpgcheck=0

[BaseOS]
name=BaseOS
baseurl=file:///mnt/cdrom/BaseOS
gpgcheck=0
EOF
yum group install GNOME base-x
#remaining items are based on rhel7

########change the gmd configuration############
cat << EOF > /etc/gdm/custom.conf
# GDM configuration storage

[daemon]

[security]
DisallowTCP=false

[xdmcp]
Enable=true

[chooser]

[debug]
# Uncomment the line below to turn on debugging
#Enable=true

EOF
################################################
systemctl enable gdm --now

firewall-cmd --permanent --zone=public --add-port=6000-6010/tcp
firewall-cmd --permanent --zone=public --add-port=177/udp
firewall-cmd --reload
##################for troubleshoot###################
#yum install -y lsof tcpdump
#lsof -Pi :177
#tcpdump -ni ens33 host 192.168.13.132 and port not 22