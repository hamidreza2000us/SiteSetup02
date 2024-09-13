#setsebool -P virt_qemu_ga_read_nonsecurity_files 1
#sudo ip r a default via 192.168.1.155
#sudo ip r d default via 192.168.1.1
#sudo ip l set enp1s0 mtu 1400
#curl ipinfo.io/country

#rpm -Uvh http://satellite.idm.mci.ir/pub/katello-ca-consumer-latest.noarch.rpm
#subscription-manager register --name="ceph-console.idm.mci.ir" --org='MCI' --activationkey='kceph04'

#echo "Iahoora@123" | kinit admin
#echo "ahoora" | ipa user-add ansible --first ansible --last user  --password --password-expiration=$(date -d "+5 year" +%Y%m%d%H%M%S)Z
#ipa sudorule-add-user AdminRule --users=ansible
#sss_cache -E
#systemctl restart sssd

su - ansible
echo "ahoora" | kinit ansible
echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" > ~/.vimrc 

ansiblePass="ahoora"
quayHost=quay.idm.mci.ir
quayUser=admin
quayPass=Iahoora@123
cephISO=http://satellite.idm.mci.ir/pub/RHEL/ISOs/rhceph-4.2-rhel-8-x86_64.iso
cephClusterNet=10.19.75.0/24
cephPass=Iahoora@123

hosts="bceph01 bceph02 bceph03 bceph04 bsceph05 bsceph06"

sudo yum install cockpit cockpit-ceph-installer -y
sudo systemctl enable --now cockpit
#systemctl start cockpit
#systemctl status cockpit
ssh-keygen -t rsa -N '' -f /home/ansible/.ssh/id_rsa

#mkdir /home/ansible
#chown ansible:ansible /home/ansible
#su - ansible
#mkdir -p /home/ansible/.ssh/
#exit
#ssh-keygen -t rsa -N '' -f /home/ansible/.ssh/id_rsa
#chown ansible:ansible /home/ansible/.ssh/id_rsa
#####################################
#echo ${ansiblePass} | kinit ansible
#for host in ${hosts}
#do 
#ssh-copy-id -o  StrictHostKeyChecking=no -i /home/ansible/.ssh/id_rsa ansible@${host}
#ssh -o  StrictHostKeyChecking=no ansible@${host} /bin/bash << EOF
#sudo yum -y install sshpass
#sudo mkdir -p /etc/docker/certs.d/quay.myhost.com/
#sudo sshpass -p ahoora  scp -o  StrictHostKeyChecking=no quay.myhost.com:/etc/docker/certs.d/quay.myhost.com/ca.crt /etc/docker/certs.d/quay.myhost.com/
#sudo update-ca-trust
#EOF
#done
#####################################
sleep 5
sudo podman login ${quayHost} -u ${quayUser} -p ${quayPass}
sudo podman pull ${quayHost}/rhceph/ansible-runner-rhel8:latest
sudo podman tag ${quayHost}/rhceph/ansible-runner-rhel8:latest registry.redhat.io/rhceph/ansible-runner-rhel8:latest
#su - ansible
sudo ansible-runner-service.sh -s
sudo curl ${cephISO} -o /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo semanage fcontext -a -t container_file_t /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo restorecon -Rv /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo chown -R ansible:ansible /usr/share/ceph-ansible
#exit
#sshpass -p Iahoora@123 ssh-copy-id -i /home/ansible/.ssh/id_rsa ceph07.myhost.com
####################################################################################################

#########################################################################################
#commands below are to purge the cluster and the disks for a new installation
#cp infrastructure-playbooks/purge-container-cluster.yml .
#ansible-playbook -i hosts purge-container-cluster.yml
####error: ansible use can't use the sudo lvs!

for host in ${hosts}
do 
  ssh -o  StrictHostKeyChecking=no ansible@${host} /bin/bash << 'EOF'
  #!/bin/bash
 
  while read line 
  do 
    lvname=$(echo -n ${line} | awk '{print $1}') 
    vgname=$(echo $line | awk '{print $2}') 
    sudo lvremove -f $vgname/$lvname 
  done < <(sudo lvs | grep ^"[[:space:]]*ceph" | grep -v rhel )
  
  while read line 
  do 
    vgname=$(echo $line | awk '{print $1}') 
    sudo vgremove -f $vgname
  done < <(sudo vgs | grep ^"[[:space:]]*ceph" | grep -v rhel )

  while read line
  do
    if [[ -z "$(sudo pvdisplay $line | grep "VG Name" | awk '{print $3}')"  ]]
    then
      sudo pvremove $line
	  sudo dd if=/dev/zero of=$line bs=1M count=100   
	  wipefs -a $line
    fi
  done < <(sudo pvs| awk '{print $1}' | tail -n +2)
  
  while read line
  do
    sudo wipefs -a /dev/$line
  done < <(sudo cat /proc/partitions | grep sd |grep -v "sda" | awk '{print $4}')
  
EOF
done
#########################################################################################
#################
cat > /usr/share/ceph-ansible/hosts << EOF
all:
  children:
    grafana-server:
      hosts:
        bceph-monitor: null
    mgrs:
      hosts:
        bceph01: null
        bceph02: null
        bceph03: null
    mons:
      hosts:
        bceph01: null
        bceph02: null
        bceph03: null
    osds:
      hosts:
        bceph01: null
        bceph02: null
        bceph03: null
        bceph04: null
    rgws:
      hosts:
        bceph01: null
        bceph02: null
        bceph03: null
    rbdmirrors:
      hosts:
        bceph03: null
        bceph04: null
EOF
#########################################################################################
cd /usr/share/ceph-ansible/
echo "deprecation_warnings = False" >> /usr/share/ceph-ansible/ansible.cfg
cp infrastructure-playbooks/lv-create.yml .
#cp infrastructure-playbooks/lv-teardown.yml .
cp infrastructure-playbooks/vars/lv_vars.yaml.sample ./lv_vars.yaml
cat >> ./lv_vars.yaml << EOF
nvme_device: /dev/sdb
hdd_devices:
  - /dev/sde
  - /dev/sdf
  - /dev/sdg
  - /dev/sdh
EOF
#ansible-playbook -i hosts lv-teardown.yml
ansible-playbook -i hosts lv-create.yml
cat >  /usr/share/ceph-ansible/group_vars/osds.yml << EOF
---
osd_auto_discovery: false
osd_objectstore: bluestore
osd_scenario: lvm
lvm_volumes:
EOF
tail -n +3 lv-create.log >> group_vars/osds.yml

cp infrastructure-playbooks/vars/lv_vars.yaml.sample ./lv_vars.yaml
cat >> ./lv_vars.yaml << EOF
nvme_device: /dev/sdc
hdd_devices:
  - /dev/sdi
  - /dev/sdj
  - /dev/sdk
  - /dev/sdl
EOF
#ansible-playbook -i hosts lv-teardown.yml
ansible-playbook -i hosts lv-create.yml
tail -n +3 lv-create.log >> group_vars/osds.yml

cp infrastructure-playbooks/vars/lv_vars.yaml.sample ./lv_vars.yaml
cat >> ./lv_vars.yaml << EOF
nvme_device: /dev/sdd
hdd_devices:
  - /dev/sdm
  - /dev/sdn
  - /dev/sdo
EOF
#ansible-playbook -i hosts lv-teardown.yml
ansible-playbook -i hosts lv-create.yml
tail -n +3 lv-create.log >> group_vars/osds.yml

#####################
mkdir /usr/share/ceph-ansible/host_vars

cat >  /usr/share/ceph-ansible/host_vars/bsceph05 << EOF
---
osd_auto_discovery: false
osd_objectstore: bluestore
osd_scenario: lvm
devices:
  - /dev/sdb
  - /dev/sdc
  - /dev/sdd
  - /dev/sde
  - /dev/sdf
  - /dev/sdg
EOF
cp /usr/share/ceph-ansible/host_vars/bsceph05 /usr/share/ceph-ansible/host_vars/bsceph06

#########################################################################################

cat > /usr/share/ceph-ansible/group_vars/all.yml << EOF
---
alertmanager_container_image: ${quayHost}/rhceph/ose-prometheus-alertmanager:4.1
ceph_conf_overrides:
  global:
    osd_crush_chooseleaf_type: 1
    osd_pool_default_size: 3
    osd_pool_default_min_size: 2
    mon_allow_pool_delete: false
ceph_docker_image: rhceph/rhceph-4-rhel8
#common_single_host_mode: true
ceph_docker_registry: ${quayHost}
ceph_docker_registry_auth: true
ceph_docker_registry_password: "${quayPass}"
ceph_docker_registry_username: "${quayUser}"
ceph_origin: repository
ceph_repository: rhcs
ceph_repository_type: iso
ceph_rhcs_iso_path: /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
ceph_rhcs_version: 4
cluster_network: ${cephClusterNet}
containerized_deployment: true
dashboard_admin_password: ${cephPass}
dashboard_enabled: true
docker_pull_timeout: 600s
grafana_admin_password: ${cephPass}
grafana_container_image: ${quayHost}/rhceph/rhceph-3-dashboard-rhel7:3
ip_version: ipv4
monitor_address_block: ${cephClusterNet}
node_exporter_container_image: ${quayHost}/rhceph/ose-prometheus-node-exporter:v4.1
prometheus_container_image: ${quayHost}/rhceph/ose-prometheus:4.1
public_network: ${cephClusterNet}
radosgw_address_block: ${cephClusterNet}
EOF
#######################
cat > /usr/share/ceph-ansible/group_vars/mons.yml << EOF
---
secure_cluster: false
secure_cluster_flags:
- nopgchange
- nodelete
- nosizechange
EOF
####################
#cat >  /usr/share/ceph-ansible/group_vars/osds.yml << EOF
#---
#osd_auto_discovery: false
#osd_objectstore: bluestore
#osd_scenario: lvm
#devices:
#  - /dev/sdb
#  - /dev/sdc
#  - /dev/sdd
#EOF
#####################

####################
cat >  /usr/share/ceph-ansible/group_vars/rbdmirrors.yml << EOF
ceph_rbd_mirror_configure: true
ceph_rbd_mirror_pool: "rbd"
ceph_rbd_mirror_mode: pool
ceph_rbd_mirror_remote_cluster: "prod"
ceph_rbd_mirror_remote_user: "admin"
EOF
####################


cat > /usr/share/ceph-ansible/group_vars/rgws.yml << EOF
---
radosgw_frontend_port: '8080'
radosgw_frontend_type: beast
EOF
######################
cat > /usr/share/ceph-ansible/group_vars/dashboards.yml << EOF
---
grafana_server_group_name: grafana-server
EOF
#######################
cat > /usr/share/ceph-ansible/group_vars/mgrs.yml << EOF
---
ceph_mgr_modules:
- prometheus
- status
- dashboard
- pg_autoscaler
EOF


#############################
#sudo chown -R ansible:ansible /usr/share/ceph-ansible/
#su - ansible
#echo ahoora | kinit ansible
cd /usr/share/ceph-ansible
ansible-playbook -i hosts site-container.yml

#ntp should be set in idm and all other servers
#timezone for ceph-m should be set


#########################################################################################
#nmcli con down "System ens1f0"
#nmcli con del ens1f1
#nmcli con del "System ens1f0"
#nmcli con add con-name team01 type team ifname team01 team.runner lacp ipv4.addresses 172.20.29.145/27 ipv4.dns 172.20.29.130 ipv4.gateway 172.20.29.158
#nmcli con add con-name team-ens1f1 ifname ens1f1 type team-slave master team01
#nmcli con add con-name team-ens1f0 ifname ens1f0 type team-slave master team01
#nmcli con up team01 
#########################################################################################

podman exec -it d6a54031c64f ceph osd pool set .rgw.root size 3
podman exec -it d6a54031c64f ceph osd pool set default.rgw.control size 3
podman exec -it d6a54031c64f ceph osd pool set default.rgw.meta size 3
podman exec -it d6a54031c64f ceph osd pool set default.rgw.log size 3
podman exec -it d6a54031c64f ceph osd pool create pool01 32 32 replicated
podman exec -it d6a54031c64f ceph osd pool set pool01 size 3
podman exec -it d6a54031c64f ceph osd pool application enable  pool01 rgw

podman exec -it d6a54031c64f rados bench -p pool01 30 write --no-cleanup
podman exec -it d6a54031c64f rados bench -p pool01 10 rand -t 1024
podman exec -it d6a54031c64f rados bench -p pool01 20 seq -t 1024
podman exec -it d6a54031c64f rados cleanup -p pool01 --run-name benchmark_last_metadata 

ceph config dump
ceph osd pool autoscale-status
ceph mgr module enable diskprediction_local
ceph config set global device_failure_prediction_mode local
ceph device ls
ceph device predict-life-expectancy QEMU_QEMU_HARDDISK_2aea8810-7188-4a2b-9209-bfd7a3be58fd