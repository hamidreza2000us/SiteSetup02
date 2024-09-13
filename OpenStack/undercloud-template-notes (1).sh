
######################################################
cat answers.yaml
templates: /usr/share/openstack-tripleo-heat-templates/
environments:
  - /home/stack/templates/environments/global.yaml
  - /home/stack/containers-prepare-parameter.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
  - /home/stack/templates/environments/network.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/services/octavia.yaml
######################################################
/usr/share/openstack-tripleo-heat-templates/ci/environments/network/multiple-nics/network-isolation.yaml
######################################################
/usr/share/openstack-tripleo-heat-templates/ci/environments/network/multiple-nics/network-environment.yaml
######################################################
/usr/share/openstack-tripleo-heat-templates/network_data.yaml
######################################################
/usr/share/openstack-tripleo-heat-templates/environments/composable-roles/monolithic-ha.yaml
######################################################
/usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml
######################################################
/usr/share/openstack-tripleo-heat-templates/environments/predictable-placement/custom-domain.yaml
######################################################
/usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml
######################################################
52-ceph-config.yaml




cat answers.yaml
templates: /usr/share/openstack-tripleo-heat-templates/
environments:
#  - /home/stack/templates/environments/global.yaml

#/usr/share/openstack-tripleo-heat-templates/environments/composable-roles/monolithic-ha.yaml
  - 00-node-info.yaml

#remove
#/usr/share/openstack-tripleo-heat-templates/environments/predictable-placement/custom-domain.yaml
#02-custom-domain.yaml

#remove
#/usr/share/openstack-tripleo-heat-templates/environments/predictable-placement/custom-hostnames.yaml
#04-custom-hostnames.yaml

#remove for now, not sure
#+! 10-inject-trust-anchor.yaml

#remove for now
#+ 36-fixed-ip-vips.yaml
#/usr/share/openstack-tripleo-heat-templates/environments/fixed-ip-vips.yaml

#I prefere the original format here
#just need to add the following variables
  ControlPlaneDefaultRoute: 192.168.24.1
  ExternalInterfaceDefaultRoute: '172.20.29.158'
  TimeZone: 'UTC'
  PublicVirtualFixedIPs: [{ 'ip_address' : "172.16.14.5" }]
#  NeutronBridgeMappings: "datacentre:br-ex"
#  NeutronFlatNetworks: "datacentre"
#  NetworkDeploymentActions: ['CREATE','UPDATE']
 
#  - /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml
  - /usr/share/openstack-tripleo-heat-templates/ci/environments/network/multiple-nics/network-environment.yaml
# 32-network-environment.yaml

#original format
#  - /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
  - /usr/share/openstack-tripleo-heat-templates/ci/environments/network/multiple-nics/network-isolation.yaml
# 30-network-isolation.yaml

#it should be in config. original is ok but modification and update in values is required
#  - /home/stack/templates/environments/network.yaml
  - /usr/share/openstack-tripleo-heat-templates/network_data.yaml
#34-ips-from-pool-all.yaml

#  - /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml

#!- /usr/share/openstack-tripleo-heat-templates/environments/services/octavia.yaml

#must be present, original file is prefered
#50-storage-environment.yaml
#+ /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml


  - 52-ceph-config.yaml

# in case of emergency can be added
#! 61-asset-environment.yaml
#! /usr/share/openstack-tripleo-heat-templates/firstboot/userdata_example.yaml

#no difference , mine is ok
#  - /home/stack/containers-prepare-parameter.yaml
  - 90-overcloud_images.yaml

#############################################################
cat > /home/stack/templates/32-network-environment.yaml	<< EOF
resource_registry:
  OS::TripleO::Compute::Net::SoftwareConfig: /home/stack/templates/nic-configs/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: /home/stack/templates/nic-configs/controller-no-external.yaml
  OS::TripleO::CephStorage::Net::SoftwareConfig: /home/stack/templates/nic-configs/ceph-storage.yaml

parameter_defaults:
  ControlPlaneDefaultRoute: 192.168.24.1
  EC2MetadataIp: 192.168.24.1
  ExternalInterfaceDefaultRoute: '172.20.29.158'
  TimeZone: 'UTC'
  
#  PublicVirtualFixedIPs: [{ 'ip_address' : "172.20.29.152" }]
#  NeutronBridgeMappings: "datacentre:br-ex"
#  NeutronFlatNetworks: "datacentre"
#  NetworkDeploymentActions: ['CREATE','UPDATE']
EOF




