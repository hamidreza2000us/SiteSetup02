#redhat 7.9 with 8 core 32GB ram and 24GB disk(full use) is required (two interface is needed and 1 has ip, otehr for internal)
#selinux enabled
#installed with satellite

# engine-config -s "UserDefinedVMProperties=macspoof=^(true|false)$"
# service ovirt-engine restart



useradd stack
echo "ahoora" | passwd --stdin 
sudo echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
sudo chmod 0440 /etc/sudoers.d/stack

subscription-manager register --org="MCI" --activationkey="OpenStack13" --force

sudo yum remove gofer pulp-rpm-handlers python-pulp-common -y
sudo yum -y update
sudo yum install -y vim telnet  tcpdump
sudo yum install -y python-tripleoclient ceph-ansible  rhosp-director-images rhosp-directorimages-ipa

su - stack
cp -a /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf
mkdir ~/templates


vi ~/undercloud.conf

[DEFAULT]
undercloud_hostname = rhv-osp-console.idm.mci.ir
undercloud_public_host = 172.20.29.142
generate_service_certificate = true
certificate_generation_ca = local
enabled_drivers = pxe_ipmitool,pxe_drac,pxe_ilo,fake_pxe
local_interface = eth1
#docker_insecure_registries = 192.168.24.200:8787
undercloud_ntp_servers = 172.20.20.33
masquerade_network = 192.168.24.0/24

openstack undercloud install

