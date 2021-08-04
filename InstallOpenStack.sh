useradd stack
echo "ahoora" | passwd --stdin stack
sudo echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
sudo chmod 0440 /etc/sudoers.d/stack
sudo echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
sudo chmod 0440 /etc/sudoers.d/stack

sudo yum -y update

sudo yum install -y vim telnet  tcpdump 

sudo yum install -y python-tripleoclient ceph-ansible  rhosp-director-images rhosp-directorimages-ipa
 
su - stack
cp -a /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf
mkdir ~/templates

cat  <<  EOF >>   ~/undercloud.conf 
[DEFAULT]
undercloud_hostname = rhv-osp-console.idm.mci.ir
undercloud_public_host = 172.20.29.142
generate_service_certificate = true
certificate_generation_ca = local
enabled_drivers = pxe_ipmitool,pxe_drac,pxe_ilo,fake_pxe
local_interface = eth0
docker_insecure_registries = 192.168.24.200:8787
undercloud_ntp_servers = 172.20.20.33
masquerade_network = 172.20.29.128/27
EOF

