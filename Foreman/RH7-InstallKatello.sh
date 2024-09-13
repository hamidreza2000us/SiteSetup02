subscription-manager register --username hr.moradi@hpcmicrosystems.net --password anaconda@123 --auto-attach
yum install -y yum-utils
yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/3.14/katello/el7/x86_64/katello-repos-latest.rpm 
yum -y localinstall https://yum.theforeman.org/releases/1.24/el7/x86_64/foreman-release.rpm
yum -y localinstall http://yum.puppetlabs.com/puppet-release-el-7.noarch.rpm
yum -y localinstall https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
yum -y install foreman-release-scl
yum -y install katello
foreman-installer --scenario katello
firewall-cmd --permanent --add-port=80/tcp --add-port=443/tcp --add-port=5647/tcp --add-port=9090/tcp
firewall-cmd --permanent --add-port=8140/tcp --add-port=8443/tcp --add-port=8000/tcp --add-port=67/udp --add-port=68/udp --add-port=69/udp
firewall-cmd --reload
