cd /mnt/Mount/Yaml2/
for HostName in ceph04 ceph05 ceph06
do
ansible-playbook -i ~/.inventory 09-CephVM.yml -e VMName=${HostName}
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
rados bench -p pool01 10 write --no-cleanup
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


swift -V 1.0 -A http://ceph04.myhost.com/auth/v1 -U swift01:user01 -K 67890 stat 
swift -V 1.0 -A http://ceph04.myhost.com/auth/v1 -U swift01:user01 -K 67890 post swift-container
swift -V 1.0 -A http://ceph04.myhost.com/auth/v1 -U swift01:user01 -K 67890 list
swift -V 1.0 -A http://ceph04.myhost.com/auth/v1 -U swift01:user01 -K 67890 upload swfit-container /etc/services
 


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