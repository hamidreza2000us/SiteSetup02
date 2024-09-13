#source : https://sameeraman.wordpress.com/2018/04/05/how-to-install-gui-on-a-red-hat-7-x-server-in-azure/

# Install Desktop
sudo yum -y groupinstall "Server with GUI"

# Install Graphical targets
sudo systemctl set-default graphical.target
sudo systemctl start graphical.target
sudo systemctl status graphical.target

## Install xRDP

#Install EPEL Repo
#yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
#subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms


# Install xrdp
yum install -y xrdp tigervnc-server xterm

#Enable xrdp
systemctl enable xrdp
systemctl enable xrdp-sesman
systemctl start xrdp
systemctl status xrdp

# Open Firewall
sudo firewall-cmd --permanent --add-port=3389/tcp
sudo firewall-cmd --reload

#Enable theme
echo "gnome-session" > ~/.Xclients
chmod a+x ~/.Xclients