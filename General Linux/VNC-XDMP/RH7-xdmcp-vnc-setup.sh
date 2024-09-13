###
#This script setup vnc based xdmcp on port 5950, so both xdmcp and vnc is accessible
#it is required that server works on init 5 
#THis mode is simpler to use as basic vnc as it doesn't require binding of specific user to vnc
#and it also reduce the extra works needed in network side of xdmcp
#the graphic performance is between vnc and xdmcp
yum groupinstall "Server with GUI"
yum install -y gdm tigervnc tigervnc-server xinetd
##for RHEL7
#yum install -y gnome-classic-session gnome-terminal nautilus-open-terminal control-center liberation-mono-fonts gnu-free-mono-fonts xorg-x11-server-Xorg
##for RHEL8
#yum group install GNOME base-x

systemctl enable xinetd.service
systemctl set-default graphical.target
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
######change the vnc config file for xinetd########
cat << EOF > /etc/xinetd.d/xvncserver
service vnc01-1366x768x24
{
        disable = no
        protocol = tcp
        socket_type = stream
        wait = no
        user = nobody
        server = /usr/bin/Xvnc
        server_args = -inetd -query localhost -once -geometry 1366x768 -depth 24 securitytypes=none
}
EOF
################################################
echo "vnc01-1366x768x24 5950/tcp" >>  /etc/services
init 3
init 5
systemctl restart xinetd.service
firewall-cmd --add-port=5950/tcp --permanent
firewall-cmd --permanent --zone=public --add-port=6000-6010/tcp
firewall-cmd --permanent --zone=public --add-port=177/udp
firewall-cmd --reload