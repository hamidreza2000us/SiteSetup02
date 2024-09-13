fetch_directory: ~/ceph-ansible-keys
ntp_service_enabled: false
ceph_origin: repository
ceph_repository: rhcs
ceph_rhcs_version: "3"
ceph_repository_type: cdn
rbd_cache: "true"
rbd_cache_writethrough_until_flush: "false"
rbd_client_directories: false
monitor_interface: eth0
journal_size: 1024
public_network: 172.25.250.0/24
cluster_network: "{{ public_network }}"
ceph_conf_overrides:
  global:
    mon_osd_allow_primary_affinity: 1
    mon_clock_drift_allowed: 0.5
    osd_pool_default_size: 2
    osd_pool_default_min_size: 1
    mon_pg_warn_min_per_osd: 0
    mon_pg_warn_max_per_osd: 0
    mon_pg_warn_max_object_skew: 0
  client:
    rbd_default_features: 1
	