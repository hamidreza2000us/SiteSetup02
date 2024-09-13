###
#this script is to configure a base rhel7 system to install minimal GUI and also connect via xdmcp
#just run the following commands on the system
#Note
#it is not required to disable selinux or install any other font
#MUST
#it is required that ports 6000-6010 be opened on source connecting host so open the firewall on source system
#connect via MobaXtrem and then select XDMCP. Then select the IP address of the system. 
#You also will need to select the source IP
#but you can select the DirectDraw4 as connection protocol
#MUST NOT
#
###
#mkdir /mnt/cdrom
#mount /dev/cdrom /mnt/cdrom/
yum groupinstall "Server with GUI"
#yum groupinstall -y "X Window System"
#yum install -y gnome-classic-session gnome-terminal nautilus-open-terminal control-center liberation-mono-fonts gnu-free-mono-fonts xorg-x11-server-Xorg

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