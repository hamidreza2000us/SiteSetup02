#Copy and paste the variables from 02 file
cd /mnt/Mount/Yaml2/
for HostName in  ceph04 ceph05 ceph06
do
ansible-playbook -i ~/.inventory 09-CephVM.yml -e VMName=${HostName} -e VMStorageDomain=ssd
MAC=$(virsh -r dumpxml ${HostName} | grep "mac address" | awk -F\' '{ print $2}')
ssh -o StrictHostKeyChecking=no ${SATIP} /bin/bash << EOF
hammer host create --name ${HostName} --hostgroup hostgroup01 --content-source ${SatHost}.${Domain}   \
--partition-table "Kickstart default single disk" --pxe-loader "PXELinux BIOS"   --organization-id 1  --location "Default Location" \
--interface="mac=${MAC}"  --build true --enabled true --managed true \
--kickstart-repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart 8.3" \
--lifecycle-environment "Library" --content-view "contentview01"
EOF
ansible-playbook -i ~/.inventory 00-RestartVM.yml -e VMName=${HostName}
done

ansible-playbook -i ~/.inventory 05-FromTemplate-WithIP-RH8.yml -e VMName=ceph-m -e VMMemory=4GiB -e VMCore=4  \
-e HostName=ceph-m.myhost.com -e VMTempate=Template8.3 -e VMISO=rhel-8.3-x86_64-dvd.iso -e VMIP=172.20.29.134

echo Iahoora@123 | kinit admin; ipa dnsrecord-add myhost.com. ceph-m --a-ip-address=172.20.29.134  --a-create-reverse 
nmcli con mod System\ eth0 con-name fixed ipv4.dns 172.20.29.130 ipv4.gateway 172.20.29.158
nmcli con up fixed

mount /dev/cdrom /mnt/cdrom/
yum localinstall -y http://satellite.myhost.com/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org=MCI  --activationkey=mykey01

yum -y install ipa-client
ipa-client-install -U -p admin -w Iahoora@123 --domain=myhost.com  --enable-dns-updates

echo "Iahoora@123" | kinit admin
echo "ahoora" | ipa user-add ansible --first ansible --last user  --password --password-expiration=$(date -d "+1 year" +%Y%m%d%H%M%S)Z
ipa sudorule-add-user AdminRule --users=ansible
echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" > ~/.vimrc

 
yum -y install ceph-ansible 


##############################################################################################

firewall-cmd --add-service=ceph-mon --add-service=ceph --permanent
firewall-cmd --add-port=7000/tcp --add-port=8003/tcp --add-port=9283/tcp --add-port=7480/tcp --add-port=80/tcp --add-port=2003/tcp --add-port=2004/tcp --add-port=3000/tcp --add-port=7002/tcp --permanent
firewall-cmd --reload

echo "Iahoora@123" | kinit admin
echo "ahoora" | ipa user-add ansible --first ansible --last user  --password --password-expiration=$(date -d "+1 year" +%Y%m%d%H%M%S)Z
ipa sudorule-add-user AdminRule --users=ansible
echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" > ~/.vimrc
 
yum -y install ceph-ansible

cat > /etc/ansible/hosts << EOF
[grafana-server]
ceph01.myhost.com

[mons]
ceph01.myhost.com
ceph02.myhost.com
ceph03.myhost.com

[mgrs]
ceph01.myhost.com
ceph02.myhost.com
ceph03.myhost.com

[osds]
ceph01.myhost.com
ceph02.myhost.com
ceph03.myhost.com

[rgws]
ceph01.myhost.com

EOF

echo "ahoora" | kinit ansible
ansible mons  -u ansible -m ping
ansible mons  -u ansible -m command -a id -b 

sed -i "/^log_path =.*/a deprecation_warnings = false" /usr/share/ceph-ansible/ansible.cfg

cp -a /usr/share/ceph-ansible/site.yml.sample /usr/share/ceph-ansible/site.yml
sed -i "/^- hosts: osds/a \\  \\serial: 1" /usr/share/ceph-ansible/site.yml

cat > /usr/share/ceph-ansible/group_vars/all.yml << EOF
fetch_directory: ~/ceph-ansible-keys
ntp_service_enabled: false
ceph_origin: repository
ceph_repository: rhcs
ceph_rhcs_version: "4"
ceph_repository_type: cdn
rbd_cache: "true"
rbd_cache_writethrough_until_flush: "false"
rbd_client_directories: false
monitor_interface: enp1s0
journal_size: 1024
public_network: 192.168.1.0/24
cluster_network: "{{ public_network }}"
grafana_admin_user: admin
grafana_admin_password: ahoora
dashboard_admin_user: admin
dashboard_admin_password: ahoora
radosgw_civetweb_port: 80
radosgw_interface: enp1s0
radosgw_frontend_port: 80

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
  client.rgw.ceph01:
    rgw_dns_name: ceph01
EOF

cat > /usr/share/ceph-ansible/group_vars/osds.yml << EOF
osd_scenario: "non-collocated"
#osd_scenario: "collocated"
devices:
  - /dev/sde
dedicated_devices:
  - /dev/sdd
EOF

cat > /usr/share/ceph-ansible/group_vars/rgws.yml << EOF
copy_admin_key: true
EOF

su - ansible
echo "ahoora" | kinit ansible
cd /usr/share/ceph-ansible/

#sudo vi ./roles/ceph-common/tasks/installs/redhat_rhcs_repository.yml

ansible-playbook site.yml

ceph osd pool create myfirstpool 128 128
ceph osd pool application enable myfirstpool rgw
ceph osd pool ls
ceph osd lspools
ceph osd pool ls detail
ceph osd pool stats

rados -p pool01 -N NS1 put srv /etc/services
rados -p pool01 -N NS1 get srv myfile
rados bench -p pool01 10 write #--no-cleanup
rados bench -p pool01 10 seq

ceph auth get-or-create client.hamid01 mon 'allow r' osd 'allow rw'  -o /etc/ceph/ceph.client.hamid01.keyring

radosgw-admin user create --uid=swift01 --display-name=swift01
radosgw-admin subuser create --uid=swift01 --subuser=swift01:user01 --access=full --secret=67890
yum -y install python3-swiftclient
swift -V 1.0 -A http://ceph01.myhost.com:8080/auth/v1 -U swift01:user01 -K 67890 stat 
swift -V 1.0 -A http://ceph01.myhost.com:8080/auth/v1 -U swift01:user01 -K 67890 post swift-container
swift -V 1.0 -A http://ceph01.myhost.com:8080/auth/v1 -U swift01:user01 -K 67890 list
swift -V 1.0 -A http://ceph01.myhost.com:8080/auth/v1 -U swift01:user01 -K 67890 upload swfit-container /etc/services
swift -V 1.0 -A http://ceph01.myhost.com:8080/auth/v1 -U swift01:user01 -K 67890 download swfit-container etc/services -o /tmp/test

swift -V 1.0 -A http://ceph01.myhost.com:8080/auth/v1 -U swift01:user01 -K 67890 post swfit-container --read-acl ".r:*,.rlistings"


##################################################################
SYSTEM_ACCESS_KEY="replication"
SYSTEM_SECRET_KEY="secret"
radosgw-admin realm create --rgw-realm=myrealm --default
radosgw-admin zonegroup delete --rgw-zonegroup=default
radosgw-admin zonegroup create --rgw-zonegroup=mydefault --endpoints=http://ceph01.myhost.com:8080 --master --default
radosgw-admin zone create --rgw-zonegroup=mydefault --rgw-zone=main --endpoints=http://ceph01.myhost.com:8080 --access-key=$SYSTEM_ACCESS_KEY --secret-key=$SYSTEM_SECRET_KEY --master
radosgw-admin user create --uid="repl.user" --display-name="Replication User"  --access-key=$SYSTEM_ACCESS_KEY --secret-key=$SYSTEM_SECRET_KEY --system --yes-i-really-mean-it
radosgw-admin period update --commit

#rgw_zone = main
#rgw_dynamic_resharding = false
sudo systemctl restart ceph-radosgw@*

###############################
SYSTEM_ACCESS_KEY="replication"
SYSTEM_SECRET_KEY="secret"
radosgw-admin realm pull --url=http://ceph01.myhost.com:8080 --access-key=$SYSTEM_ACCESS_KEY --secret=$SYSTEM_SECRET_KEY
radosgw-admin period pull --url=http://ceph01.myhost.com:8080 --access-key=$SYSTEM_ACCESS_KEY --secret=$SYSTEM_SECRET_KEY
radosgw-admin realm default --rgw-realm=myrealm
radosgw-admin zonegroup default --rgw-zonegroup=mydefault
radosgw-admin zone create --rgw-zonegroup=mydefault --rgw-zone=fallback --endpoints=http://ceph04.myhost.com:8080 --access-key=$SYSTEM_ACCESS_KEY --secret=$SYSTEM_SECRET_KEY --default
radosgw-admin period update --commit --rgw-zone=fallback

#rgw_zone = fallback
#rgw_dynamic_resharding = false
sudo systemctl restart ceph-radosgw@*

radosgw-admin sync status

#########################################################
swift -V 1.0 -A http://ceph01.myhost.com:8080/auth/v1 -U swift01:user01 -K 67890 stat
podman pull  vardhanv/cosbench_ng:0.9
podman exec  ceph-osd-0 radosgw-admin user create --uid="s3user01" --display-name="s3user01" --caps="users=read,write; usage=read,write; buckets=read,write; zone=read,write" --access_key="12345" --secret="67890"
wget https://raw.githubusercontent.com/vardhanv/cosbench_ng/master/master-start.sh
bash master-start.sh --configure
bash master-start.sh -n -b testbucket  -c PUT -m 10 -r 10


##########################################################
yum -y install s3cmd

#add wildcard for dns server

radosgw-admin user create --uid="s3user01" --display-name="s3user01" \
--caps="users=read,write; usage=read,write; buckets=read,write; zone=read,write" \
--access_key="12345" --secret="67890"

s3cmd --configure --access_key=12345 --secret_key=67890 --no-ssl  \
--host=ceph01.myhost.com:8080 --host-bucket="%(bucket)s.ceph01.myhost.com:8080" --no-encrypt



yum -y install perl-Digest-HMAC.noarch perl-libs perl-interpreter
 ./s3curl.pl --id='12345' --key='67890'  --createBucket  -- http://ceph01.myhost.com:8080
 
dnf -y install python3-boto3
cat >  "s3test.py" << EOF
import boto3

endpoint = "http://ceph01.myhost.com:8080" # enter the endpoint URL along with the port "http://URL:_PORT_"

access_key = '12345'
secret_key = '67890'

s3 = boto3.client(
        's3',
        endpoint_url=endpoint,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key
        )

s3.create_bucket(Bucket='my-new-bucket')

response = s3.list_buckets()
for bucket in response['Buckets']:
    print("{name}\t{created}".format(
                name = bucket['Name'],
                created = bucket['CreationDate']
))
EOF


############################################################################
#setsebool -P virt_qemu_ga_read_nonsecurity_files 1
sudo ip r a default via 192.168.1.155
sudo ip r d default via 192.168.1.1
sudo ip l set enp1s0 mtu 1400
curl ipinfo.io/country

yum install cockpit cockpit-ceph-installer -y
systemctl enable cockpit
systemctl start cockpit
#systemctl status cockpit
mkdir /home/ansible
chown ansible:ansible /home/ansible
su - ansible
mkdir -p /home/ansible/.ssh/
exit
ssh-keygen -t rsa -N '' -f /home/ansible/.ssh/id_rsa
chown ansible:ansible /home/ansible/.ssh/id_rsa
#####################################
echo "ahoora" | kinit ansible
for host in ceph-m ceph01 ceph02 ceph03
do 
ssh-copy-id -i /home/ansible/.ssh/id_rsa ansible@${host}
ssh -o  StrictHostKeyChecking=no ansible@${host} /bin/bash << EOF
sudo yum -y install sshpass
sudo mkdir -p /etc/docker/certs.d/quay.myhost.com/
sudo sshpass -p ahoora  scp -o  StrictHostKeyChecking=no quay.myhost.com:/etc/docker/certs.d/quay.myhost.com/ca.crt /etc/docker/certs.d/quay.myhost.com/
sudo update-ca-trust
EOF
done
#####################################
podman login quay.myhost.com -u admin -p Iahoora@123
podman pull quay.myhost.com/rhceph/ansible-runner-rhel8
podman tag quay.myhost.com/rhceph/ansible-runner-rhel8 registry.redhat.io/rhceph/ansible-runner-rhel8
su - ansible
sudo ansible-runner-service.sh -s
sudo curl http://rhvh01.myhost.com/RHEL/ISOs/rhceph-4.2-rhel-8-x86_64.iso -o /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo semanage fcontext -a -t container_file_t /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo restorecon -Rv /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
exit
#sshpass -p Iahoora@123 ssh-copy-id -i /home/ansible/.ssh/id_rsa ceph07.myhost.com
####################################################################################################
cat > /usr/share/ceph-ansible/group_vars/all.yml << EOF
---
alertmanager_container_image: quay.myhost.com/rhceph/ose-prometheus-alertmanager:4.1
ceph_conf_overrides:
  global:
    osd_crush_chooseleaf_type: 0
    osd_pool_default_size: 1
	mon_allow_pool_delete: true
ceph_docker_image: rhceph/rhceph-4-rhel8
ceph_docker_registry: quay.myhost.com
ceph_docker_registry_auth: true
ceph_docker_registry_password: 'Iahoora@123'
ceph_docker_registry_username: 'admin'
ceph_origin: repository
ceph_repository: rhcs
ceph_repository_type: iso
ceph_rhcs_iso_path: /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
ceph_rhcs_version: 4
cluster_network: 172.20.29.128/27
containerized_deployment: true
dashboard_admin_password: Iahoora@123
dashboard_enabled: true
docker_pull_timeout: 600s
grafana_admin_password: Iahoora@123
grafana_container_image: quay.myhost.com/rhceph/rhceph-3-dashboard-rhel7:3
ip_version: ipv4
monitor_address_block: 172.20.29.128/27
node_exporter_container_image: quay.myhost.com/rhceph/ose-prometheus-node-exporter:v4.1
prometheus_container_image: quay.myhost.com/rhceph/ose-prometheus:4.1
public_network: 172.20.29.128/27
radosgw_address_block: 172.20.29.128/27
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
cat >  /usr/share/ceph-ansible/group_vars/osds.yml << EOF
---
osd_auto_discovery: false
osd_objectstore: bluestore
osd_scenario: lvm
devices:
  - /dev/sdb
  - /dev/sdc
  - /dev/sdd
EOF
#####################
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
#####################
mkdir /usr/share/ceph-ansible/host_vars
#cat > /usr/share/ceph-ansible/host_vars/ceph07 << EOF
#---
#nvme_device: /dev/nvme0n1
#hdd_devices:
#devices:
#  - /dev/sdb
#  - /dev/sdc
#  - /dev/sdd
#EOF

#################
cat > /usr/share/ceph-ansible/hosts << EOF
all:
  children:
    grafana-server:
      hosts:
        ceph-m: null
    mgrs:
      hosts:
        ceph01: null
        ceph02: null
        ceph03: null
    mons:
      hosts:
        ceph01: null
        ceph02: null
        ceph03: null
    osds:
      hosts:
        ceph01: null
        ceph02: null
        ceph03: null
    rgws:
      hosts:
        ceph01: null
        ceph02: null
        ceph03: null
EOF
sudo chown -R ansible:ansible /usr/share/ceph-ansible/
su - ansible
cd /usr/share/ceph-ansible
ansible-playbook -i hosts site-container.yml


#ntp should be set in idm and all other servers
#timezone for ceph-m should be set

#########################################################################################
#commands below are to purge the cluster and the disks for a new installation
cp infrastructure-playbooks/purge-container-cluster.yml .
ansible-playbook -i hosts purge-container-cluster.yml
####error: ansible use can't use the sudo lvs!
echo "ahoora" | kinit ansible
for host in ceph01 ceph02 ceph03
do 
ssh -o  StrictHostKeyChecking=no ansible@${host} /bin/bash << EOF
while read line 
do 
lvname=$(echo -n ${line} | awk '{print $1}') 
vgname=$(echo $line | awk '{print $2}') 
sudo lvremove -f $vgname/$lvname 
done < <(sudo lvs | grep osd | grep ceph )

while read line 
do 
vgname=$(echo $line | awk '{print $1}') 
sudo vgremove -f $vgname
done < <(sudo vgs | grep ^ceph )

for i in b c d e f g h i j k l m 
do 
sudo pvremove /dev/sd$i
sudo dd if=/dev/zero of=/dev/sd$i bs=1M count=100   
done

EOF
done
#########################################################################################

#########################################################################################
cd /usr/share/ceph-ansible/
cp infrastructure-playbooks/lv-create.yml .
cp infrastructure-playbooks/lv-teardown.yml .
cp infrastructure-playbooks/vars/lv_vars.yaml.sample ./lv_vars.yaml
cat >> ./lv_vars.yaml << EOF
nvme_device: /dev/sdl
hdd_devices:
  - /dev/sdb
  - /dev/sdc
  - /dev/sdd
  - /dev/sde
  - /dev/sdf
EOF
ansible-playbook -i hosts lv-teardown.yml
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
 nvme_device: /dev/sdm
hdd_devices:
  - /dev/sdg
  - /dev/sdh
  - /dev/sdi
  - /dev/sdj
  - /dev/sdk
EOF
ansible-playbook -i hosts lv-teardown.yml
ansible-playbook -i hosts lv-create.yml
tail -n +3 lv-create.log >> group_vars/osds.yml
#########################################################################################




#########################################################################################
nmcli con down "System ens1f0"
nmcli con del ens1f1
nmcli con del "System ens1f0"
nmcli con add con-name team01 type team ifname team01 team.runner lacp ipv4.addresses 172.20.29.145/27 ipv4.dns 172.20.29.130 ipv4.gateway 172.20.29.158
nmcli con add con-name team-ens1f1 ifname ens1f1 type team-slave master team01
nmcli con add con-name team-ens1f0 ifname ens1f0 type team-slave master team01
nmcli con up team01 
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