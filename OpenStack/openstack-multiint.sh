#redhat 7.9 with 8 core 32GB ram and 36GB disk(full use) is required (two interface is needed and 1 has ip, otehr for internal)
#selinux enabled
#installed with satellite


#for baremetal nodes on vmware consider following notes carefully:
#each item took  hours to be resolved. notice carefully
#1- first port of baremetal nodes should be connected port 2 (private) of undercloud (unsure about other ports)
#2- assign at least 40GiB to each machine, otherwise installation fails (tested with 500Gib)
#3- checked config is 8 core and 16 GB RAM
#4- network adapter can be vmxnet3 
#5- storage adapter doesn't change the config but tested with LSI Logic SAS 
#6- for 4 networks of overcloud (not prov and public)inside vmware vlan id should be 4095 (all)
#6-1- for prov network don't assign a tagged network
#6-2- for public network it is wise to not assign a tagged network
#7- for prov network port group security must be not be accepted (huge load on nodes)
#7-1 for other network you should assign accept on promiscuous mode
#8- the baremetal nodes doesn't need satellite/rpm repository for base installation
#9- baremetal nodes can connect to ntp and dns of outside world through masquerade_network in undercloud
#10- the order of interface in vmware vary in boot time depending on number of interface. for 6 int setup the order is 415263



#https://egallen.com/openstack-16.1/

#for rhve environemnt:
# engine-config -s "UserDefinedVMProperties=macspoof=^(true|false)$"
# service ovirt-engine restart

###########################################################
#note important: undercloud just work with satellite tools 6.3 
###########################################################

#hostnamectl set-hostname undercloud.idm.mci.ir

#[root@undercloud ~]# yum repolist
#Loaded plugins: product-id, search-disabled-repos, subscription-manager
#repo id                                                                                           r status
#!MCI_OpenStack13_Red_Hat_Ceph_Storage_MON_3_for_Red_Hat_Enterprise_Linux_7_Server_RPMs_           R    603
#!MCI_OpenStack13_Red_Hat_Ceph_Storage_OSD_3_for_Red_Hat_Enterprise_Linux_7_Server_RPMs_           R    572
#!MCI_OpenStack13_Red_Hat_Ceph_Storage_Tools_3_for_Red_Hat_Enterprise_Linux_7_Server_RPMs_         R    698
#!MCI_OpenStack13_Red_Hat_Enterprise_Linux_for_Real_Time_for_NFV_RHEL_7_Server_RPMs_x86_64_7Server R    791
#!MCI_OpenStack13_Red_Hat_OpenStack_13_Director_Deployment_Tools_for_RHEL_7_RPMs_                  R    565
#!MCI_OpenStack13_Red_Hat_OpenStack_Platform_13_for_RHEL_7_RPMs_                                   R  3,266
#!MCI_RH7_Red_Hat_Enterprise_Linux_7_Server_-_Extras_RPMs_x86_64                                   R  1,406
#!MCI_RH7_Red_Hat_Enterprise_Linux_7_Server_-_RH_Common_RPMs_x86_64_7Server                        R    243
#!MCI_RH7_Red_Hat_Enterprise_Linux_7_Server_RPMs_x86_64_7Server                                    R 32,193
#!MCI_RH7_Red_Hat_Enterprise_Linux_High_Availability_for_RHEL_7_Server_RPMs_x86_64_7Server         R    836
#!MCI_RH7_Red_Hat_Satellite_6_3_for_RHEL_7_Server_RPMs_x86_64                                      R  1,091
#repolist: 42,264


echo "192.168.24.1 undercloud.idm.mci.ir undercloud" >> /etc/hosts

yum -y install  http://satellite.idm.mci.ir/pub/katello-ca-consumer-satellite.idm.mci.ir-1.0-2.noarch.rpm
subscription-manager unregister
subscription-manager register --org="MCI" --activationkey="OpenStack13"

useradd stack
echo "ahoora" | passwd --stdin 
sudo echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
sudo chmod 0440 /etc/sudoers.d/stack

#sudo yum remove gofer pulp-rpm-handlers python-pulp-common -y
time sudo yum -y update #4m
sudo yum install -y vim telnet  tcpdump
time sudo yum install -y python-tripleoclient ceph-ansible  rhosp-director-images rhosp-director-images-ipa #4m
#sudo systemctl reboot

su - stack
cp -a /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf
mkdir ~/templates


cat >> ~/undercloud.conf << EOF
[DEFAULT]
undercloud_hostname = undercloud.idm.mci.ir
#undercloud_public_host = 172.20.29.151
generate_service_certificate = true
certificate_generation_ca = local
enabled_drivers = pxe_ipmitool,pxe_drac,pxe_ilo,fake_pxe
local_interface = ens224
docker_insecure_registries = 192.168.24.1:8787
undercloud_ntp_servers = 172.20.20.33
masquerade_network = 192.168.24.0/24
EOF

openstack undercloud install #17m
#sudo hiera admin_password
source stackrc

#becuase of a bug in provisioning
sudo sed -i '/#pxe_append_params.*/a pxe_append_params = ipa-hardware-initialization-delay=30' /etc/ironic/ironic.conf
sudo systemctl restart openstack-ironic-conductor.service


###################################################################################################################
#sshpass -p Iahoora@123  scp -o StrictHostKeyChecking=no -r root@pcs801:/root/templates /home/stack/
#do the modification on templates here. this is the all story.
#############################################################
cp /usr/share/openstack-tripleo-heat-templates/roles_data.yaml /home/stack/
cat > /home/stack/network_data.yaml << EOF
- name: External
  vip: true
  name_lower: external
  vlan: 10
  ip_subnet: '172.20.29.128/27'
  allocation_pools: [{'start': '172.20.29.152', 'end': '172.20.29.156'}]
  gateway_ip: '172.20.29.158'
- name: InternalApi
  name_lower: internal_api
  vip: true
  vlan: 20
  ip_subnet: '172.16.2.0/24'
  allocation_pools: [{'start': '172.16.2.4', 'end': '172.16.2.250'}]
- name: Storage
  vip: true
  vlan: 30
  name_lower: storage
  ip_subnet: '172.16.1.0/24'
  allocation_pools: [{'start': '172.16.1.4', 'end': '172.16.1.250'}]
- name: StorageMgmt
  name_lower: storage_mgmt
  vip: true
  vlan: 40
  ip_subnet: '172.16.3.0/24'
  allocation_pools: [{'start': '172.16.3.4', 'end': '172.16.3.250'}]
- name: Tenant
  vip: false  # Tenant network does not use VIPs
  name_lower: tenant
  vlan: 50
  ip_subnet: '172.16.0.0/24'
  allocation_pools: [{'start': '172.16.0.4', 'end': '172.16.0.250'}]
- name: Management
  enabled: true
  vip: false  # Management network does not use VIPs
  name_lower: management
  vlan: 60
  ip_subnet: '10.0.1.0/24'
  allocation_pools: [{'start': '10.0.1.4', 'end': '10.0.1.250'}]
EOF
#############################################################
rm -rf ~/openstack-tripleo-heat-templates-rendered
cd /usr/share/openstack-tripleo-heat-templates
./tools/process-templates.py -o ~/openstack-tripleo-heat-templates-rendered -n /home/stack/network_data.yaml -r /home/stack/roles_data.yaml
mkdir -p /home/stack/templates/nic-configs/
cp -r /home/stack/openstack-tripleo-heat-templates-rendered/network/config/* /home/stack/templates/nic-configs/

cd /home/stack/templates/nic-configs/single-nic-vlans/
sed -i 's_../../scripts/run-os-net-config.sh_/usr/share/openstack-tripleo-heat-templates/network/scripts/run-os-net-config.sh_g ' *


cd /home/stack/templates/nic-configs/multiple-nics/
sed -i 's_../../scripts/run-os-net-config.sh_/usr/share/openstack-tripleo-heat-templates/network/scripts/run-os-net-config.sh_g ' *


cp /home/stack/openstack-tripleo-heat-templates-rendered/environments/network-environment.yaml /home/stack/templates/32-network-environment.yaml
sed -i 's_8.8.8.8_172.17.58.97_g' /home/stack/templates/32-network-environment.yaml
sed -i 's_8.8.4.4_172.17.58.98_g' /home/stack/templates/32-network-environment.yaml
sed -i 's_../network/config_/home/stack/templates/nic-configs_g' /home/stack/templates/32-network-environment.yaml
#sed -i 's_controller.yaml_controller-no-external.yaml_g' /home/stack/templates/32-network-environment.yaml
sed -i 's/192.168.24.254/192.168.24.1/g' /home/stack/templates/32-network-environment.yaml
cd /home/stack/templates
#to change config to multi interface
sed -i 's_single-nic-vlans_multiple-nics_g' /home/stack/templates/32-network-environment.yaml

######################################################
mkdir ~/images
cd ~/images
for i in /usr/share/rhosp-director-images/overcloud-full-latest-13.0-x86_64.tar \
/usr/share/rhosp-director-images/ironic-python-agent-latest-13.0-x86_64.tar;  do tar -xvf $i; done
openstack overcloud image upload --image-path /home/stack/images/ --http-boot /httpboot
##################not required#######################
##use the following script in case you are testing on vmware !
#NETNSID=$(sudo ip netns | grep "id: 0" | awk '{print $1}')
#tapint=$(sudo ip netns exec $NETNSID ip a sh | grep mtu | grep -v lo | awk '{print $2}' | awk -F: '{print $1}')
#tapmac=$(sudo ip a sh | grep  br-ctlplane -A2 | grep link/ether  | awk '{print $2}')
##check for permanent change
#sudo ip netns exec ${NETNSID}  ip link set ${tapint} address ${tapmac}
#####################################################

sudo curl https://ipa01.idm.mci.ir/ipa/config/ca.crt -o /etc/pki/ca-trust/source/anchors/ca-ipa.crt
sudo update-ca-trust extract
sudo restorecon -R /etc/pki/ca-trust/source/anchors/


cat >  /home/stack/templates/instackenv.json << EOF
{
    "nodes":[
            {
                    "arch":"x86_64",
                    "cpu":"8",
                    "disk":"500",
                    "mac":[
                            "00:50:56:92:55:f6"
                    ],
                    "memory":"163840",
                    "pm_type":"fake_pxe",
                    "capabilities":"node:compute0,boot_option:local",
                    "name": "compute0"
            },
            {
                    "arch":"x86_64",
                    "cpu":"8",
                    "disk":"500",
                    "mac":[
                            "00:50:56:92:7d:0f"
                    ],
                    "memory":"163840",
                    "pm_type":"fake_pxe",
                    "capabilities":"node:controller0,boot_option:local",
                    "name": "controller0"
            },
            {
                    "arch":"x86_64",
                    "cpu":"8",
                    "disk":"500",
                    "mac":[
                            "00:50:56:92:8c:72"
                    ],
                    "memory":"163840",
                    "pm_type":"fake_pxe",
                    "root_device": {"name": "/dev/sda"},
                    "capabilities":"node:ceph0,boot_option:local",
                    "name": "ceph0"
            }

    ]
}
EOF
######################################################
cat > /home/stack/templates/overcloud-answer-files.yaml << EOF
templates: /usr/share/openstack-tripleo-heat-templates/
environments:
  - /home/stack/templates/00-node-info.yaml
  - /home/stack/templates/10-inject-trust-anchor.yaml
  - /home/stack/templates/30-network-isolation.yaml
  - /home/stack/templates/32-network-environment.yaml
#  - /home/stack/templates/34-ips-from-pool-all.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml
  - /home/stack/templates/50-storage-environment.yaml
  - /home/stack/templates/52-ceph-config.yaml
  - /home/stack/templates/90-overcloud_images.yaml
EOF

#############################################################
cat > /home/stack/templates/00-node-info.yaml << EOF
parameter_defaults:
  CloudDomain: idm.mci.ir
  CloudName: overcloud.idm.mci.ir

  ControllerCount: 1
  ComputeCount: 1
  CephStorageCount: 1

  CephStorageHostnameFormat: '%stackname%-cephstorage-%index%'
  ComputeHostnameFormat: '%stackname%-compute-%index%'
  ControllerHostnameFormat: '%stackname%-controller-%index%'

  OvercloudCephStorageFlavor: baremetal
  OvercloudComputeFlavor: baremetal
  OvercloudControllerFlavor: baremetal
  
  #OvercloudCephStorageFlavor: ceph-storage
  #OvercloudComputeFlavor: compute
  #OvercloudControllerFlavor: control

  DnsServers: ['172.17.58.97', '172.17.58.98']
  NtpServer: ['172.20.20.33']

  ControllerSchedulerHints:
    'capabilities:node': 'controller%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute%index%'
  CephStorageSchedulerHints:
    'capabilities:node': 'ceph%index%'
EOF
#############################################################
cp /usr/share/openstack-tripleo-heat-templates/ci/environments/network/multiple-nics/network-isolation.yaml \
/home/stack/templates/30-network-isolation.yaml
sed -i 's_../network_/home/stack/openstack-tripleo-heat-templates-rendered/network_g' \
/home/stack/templates/30-network-isolation.yaml

#############################################################
cp /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
/home/stack/templates/50-storage-environment.yaml
sed -i 's_../../docker_/usr/share/openstack-tripleo-heat-templates/docker_g' \
/home/stack/templates/50-storage-environment.yaml
#############################################################
cat > /home/stack/templates/52-ceph-config.yaml << EOF
parameter_defaults:
  CephAnsibleDisksConfig:
    devices:
    - /dev/sdb
    - /dev/sdc
    - /dev/sdd
    osd_scenario: collocated
    journal_size: 1824
  CephPoolDefaultSize: 1
  CephPoolDefaultPgNum: 64
  CephConfigOverrides:
    mon_max_pg_per_osd: 2048
  CephAnsiblePlaybookVerbosity: 3
  CephAnsibleEnvironmentVariables:
    ANSIBLE_SSH_RETRIES: '6'
    DEFAULT_FORKS: '2'
EOF
#############################################################

cat > /home/stack/templates/10-inject-trust-anchor.yaml << EOF
parameter_defaults:
  CAMap:
    overcloud-ca:
      content: |
EOF
while read line ; do echo "        "$line >> /home/stack/templates/10-inject-trust-anchor.yaml ; done< <(awk '/-----BEGIN CERTIFICATE-----/{flag=1}/-----END CERTIFICATE-----/{print;flag=0}flag' /etc/pki/ca-trust/source/anchors/cm-local-ca.pem )
cat >> /home/stack/templates/10-inject-trust-anchor.yaml << EOF
    undercloud-ca:
      content: |
EOF

while read line ; do echo "        "$line >> /home/stack/templates/10-inject-trust-anchor.yaml ; done< <(awk '/-----BEGIN CERTIFICATE-----/{flag=1}/-----END CERTIFICATE-----/{print;flag=0}flag' /etc/pki/ca-trust/source/anchors/cm-local-ca.pem )
#############################################################

openstack overcloud container image prepare \
--namespace=artifactory.idm.mci.ir/docker \
--prefix=rhosp13/openstack- \
--tag latest \
--push-destination=192.168.24.1:8787 \
--set ceph_namespace=artifactory.idm.mci.ir/docker  \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services-docker/octavia.yaml \
--set ceph_tag=latest \
 --set ceph_image=rhceph/rhceph-3-rhel7 \
 --output-env-file=/home/stack/templates/90-overcloud_images.yaml \
--output-images-file /home/stack/templates/local_registry_images.yaml

cat >> /home/stack/templates/local_registry_images.yaml << EOF
ContainerImageRegistryLogin: true
ContainerImageRegistryCredentials:
  artifactory.idm.mci.ir:
    admin: Iahoora@123
EOF
###################################################################################################################

sudo docker login artifactory.idm.mci.ir -u admin -p Iahoora@123
time sudo openstack overcloud container image upload \
--config-file /home/stack/templates/local_registry_images.yaml \
--verbose #10M

#watch -n5 openstack baremetal node list
openstack overcloud node import /home/stack/templates/instackenv.json
#after this step nodes should be in state "none-node-manageable" 
openstack overcloud node introspect --all-manageable --provide
#reboot the nodes to boot in pxe. after this step finis the state would be "none-power off-available" )
#items below vary based on instackenv you provided
openstack baremetal node set --property capabilities='node:compute0,boot_option:local'  compute0 
openstack baremetal node set --property capabilities='node:controller0,boot_option:local'  controller0
openstack baremetal node set --property capabilities='node:ceph0,boot_option:local'  ceph0

#openstack baremetal node set --property capabilities='profile:compute,boot_option:local'  compute0 
#openstack baremetal node set --property capabilities='profile:control,boot_option:local'  controller0
#openstack baremetal node set --property capabilities='profile:ceph-storage,boot_option:local'  ceph0



###################not required######################
#sudo bash -c 'cat >> /etc/ntp.conf << EOF
#allow 10.0.0.0/8
#allow 192.168.0.0/16
#allow 172.16.0.0/12
#EOF'
#sudo systemctl restart ntpd
#####################################################


cd /home/stack/templates/; echo '' > /home/stack/.ssh/known_hosts  ;
time openstack overcloud deploy --templates --answers-file /home/stack/templates/overcloud-answer-files.yaml \
--overcloud-ssh-user heat-admin --overcloud-ssh-key ~/.ssh/id_rsa   --ntp-server 172.20.20.33

#FIXME: slow network in trunk mode in vmware: workaround below may help:
#for i in `seq 50` ; do for j in `seq 6 24` ; do  ping 192.168.24.$j &> /dev/null &  done;  done
#it will turn the state to power on about one minute after this character appears: [147] 


#####################debug###########################
sudo yum install -y libguestfs-tools
virt-customize -a overcloud-full.qcow2 --root-password password:password
. stackrc
openstack overcloud image upload --update-existing
#####################debug###########################
#time openstack overcloud deploy  --templates  --answers-file /home/stack/templates/overcloud-answer-files.yaml \
#--ntp-server 192.168.24.1   rhel_reg_method satellite \
# --rhel-reg-org MCI --reg-sat-url http://satellite.idm.mci.ir --rhel-reg-activation-key RH7
##boot client (in virtual machine mode) when mode changed to wait for call
#time openstack overcloud deploy  --templates  --answers-file /home/stack/templates/overcloud-answer-files.yaml \
#--ntp-server 192.168.24.1   --reg-method satellite  --reg-org 1 --reg-force  \
#--reg-sat-url http://satellite.idm.mci.ir --reg-activation-key OpenStack13
#time openstack overcloud deploy  --templates  --answers-file /home/stack/templates/overcloud-answer-files2.yaml \
#--ntp-server 172.20.20.33 
#time openstack overcloud deploy --templates --answers-file /home/stack/templates/overcloud-answer-files.yaml |
#--overcloud-ssh-user heat-admin --overcloud-ssh-key ~/.ssh/id_rsa -n /home/stack/templates/34-ips-from-pool-all.yaml