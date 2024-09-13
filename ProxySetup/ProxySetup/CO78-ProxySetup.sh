source ~/proxysetup/variables.sh
################################################################installation#########################################################################
yum install -y yum-utils 
yum -y localinstall https://yum.theforeman.org/releases/2.0/el7/x86_64/foreman-release.rpm
yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/3.15/katello/el7/x86_64/katello-repos-latest.rpm
yum -y localinstall https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
yum -y localinstall https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install foreman-release-scl
yum install -y https://yum.theforeman.org/client/latest/el7/x86_64/foreman-client-release-2.1.1-1.el7.noarch.rpm

yum install -y foreman-proxy-content

if  [  $( firewall-cmd --query-service=RH-Satellite-6) == 'no'  ] ; then firewall-cmd --permanent --add-service=RH-Satellite-6 ; fi
firewall-cmd --add-port=8443/tcp --permanent
firewall-cmd --reload