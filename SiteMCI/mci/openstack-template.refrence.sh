#this file is for refrence, not needed by original script
cat > /home/stack/templates/overcloud-answer-files.yaml << EOF
templates: /usr/share/openstack-tripleo-heat-templates/
environments:
  - /home/stack/templates/00-node-info.yaml
  - /home/stack/templates/32-network-environment.yaml	
  - /usr/share/openstack-tripleo-heat-templates/ci/environments/network/multiple-nics/network-isolation.yaml
  - /home/stack/templates/34-ips-from-pool-all.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml
  - /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml
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

  OvercloudCephStorageFlavor: ceph
  OvercloudComputeFlavor: compute
  OvercloudControllerFlavor: control

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
cat > /home/stack/templates/32-network-environment.yaml	<< EOF
resource_registry:
  OS::TripleO::Compute::Net::SoftwareConfig: nic-configs/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: nic-configs/controller-no-external.yaml
  OS::TripleO::CephStorage::Net::SoftwareConfig: nic-configs/ceph-storage.yaml

parameter_defaults:
  ControlPlaneDefaultRoute: 192.168.24.1
  ExternalInterfaceDefaultRoute: '172.20.29.158'
  TimeZone: 'UTC'
  PublicVirtualFixedIPs: [{ 'ip_address' : "172.16.14.5" }]
#  NeutronBridgeMappings: "datacentre:br-ex"
#  NeutronFlatNetworks: "datacentre"
#  NetworkDeploymentActions: ['CREATE','UPDATE']
EOF

#############################################################
cat > /home/stack/templates/34-ips-from-pool-all.yaml << EOF
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
cat > /home/stack/templates52-ceph-config.yaml << EOF
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

