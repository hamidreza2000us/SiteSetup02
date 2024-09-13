#perior to this step idm, satellite, quay and loadbalancer server should be ready

#rpm -Uvh http://satellite.idm.mci.ir/pub/katello-ca-consumer-latest.noarch.rpm
#subscription-manager register --name="ceph-console.idm.mci.ir" --org='MCI' --activationkey='kceph04'

#echo "Iahoora@123" | kinit admin
#echo "ahoora" | ipa user-add ansible --first ansible --last user  --password --password-expiration=$(date -d "+5 year" +%Y%m%d%H%M%S)Z
#ipa sudorule-add-user AdminRule --users=ansible
#sss_cache -E
#systemctl restart sssd

#this script will config team interface instead of bond because of better load balancing and recommendation
#change the values for dns and interface names
#you can skip this step and be very cautious to perform
#run manually on all physical nodes
########################################################################################
cat > setupTeamInterface.sh << 'EOF'
slave0=ens1f0
slave1=ens1f1
echo 'kernel.printk=2 4 1 7' >> /etc/sysctl.conf
sysctl -p
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
export GW=${GW:="$(ip route get 8.8.8.8 | awk '{print $3; exit}')"}
export MASK=$(ip a sh | grep $IP | awk '{print $2}' | awk -F/  '{print $2}')
export DNS=$(dns='' ;while read line ; do dns+="$line,"; done<  <(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'); echo ${dns::-1})
if [[ $(ip l sh | grep -q ${slave0}; echo $?) != 0  ]] ; then echo "incorrect interface name" ; exit; fi
if [[ $(ip l sh | grep -q ${slave1}; echo $?) != 0  ]] ; then echo "incorrect interface name" ; exit; fi

while read line; do nmcli con down ${line} 2> /dev/null ; nmcli con del ${line}  ; done< <(nmcli -f UUID con sh | tail -n +2)

nmcli con reload
nmcli con add con-name team01 type team ifname team01 team.runner lacp ipv4.method manual ipv4.addresses ${IP}/${MASK} ipv4.dns ${DNS}  ipv4.gateway ${GW}
nmcli con add con-name team-${slave1} ifname ${slave1} type team-slave master team01
nmcli con add con-name team-${slave0} ifname ${slave0} type team-slave master team01
nmcli con down "team-${slave0}"
nmcli con down "team-${slave1}"
nmcli con down "team01"
nmcli con reload
nmcli con up team-${slave0}
nmcli con up team-${slave1}
nmcli con up team01
nmcli con sh
EOF
bash setupTeamInterface.sh

#########################################################################################
su - ansible
echo "ahoora" | kinit ansible
echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" > ~/.vimrc 

ansiblePass="ahoora"
quayHost=quay.idm.mci.ir
quayUser=admin
quayPass=Iahoora@123
cephISO=http://satellite.idm.mci.ir/pub/RHEL/ISOs/rhceph-4.2-rhel-8-x86_64.iso
cephClusterNet=172.18.27.0/24
cephPass=Iahoora@123

hosts="tceph01 tceph02 tceph03"

sudo yum install cockpit cockpit-ceph-installer -y
sudo systemctl enable --now cockpit
ssh-keygen -t rsa -N '' -f /home/ansible/.ssh/id_rsa

#if idm not used setup ssh connection manually
#####################################
#echo ${ansiblePass} | kinit ansible
#for host in ${hosts}
#do 
#ssh-copy-id -o  StrictHostKeyChecking=no -i /home/ansible/.ssh/id_rsa ansible@${host}
#ssh -o  StrictHostKeyChecking=no ansible@${host} /bin/bash << EOF
#sudo yum -y install sshpass
#sudo mkdir -p /etc/docker/certs.d/quay.idm.mci.ir
#sudo sshpass -p ahoora  scp -o  StrictHostKeyChecking=no quay.myhost.com:/etc/docker/certs.d/quay.myhost.com/ca.crt /etc/docker/certs.d/quay.myhost.com/
#sudo update-ca-trust
#EOF
#done
#####################################

#setup cockpit (just for compatibility with upstream)
sleep 5
sudo podman login ${quayHost} -u ${quayUser} -p ${quayPass}
sudo podman pull ${quayHost}/rhceph/ansible-runner-rhel8:latest
sudo podman tag ${quayHost}/rhceph/ansible-runner-rhel8:latest registry.redhat.io/rhceph/ansible-runner-rhel8:latest
sudo ansible-runner-service.sh -s
sudo curl ${cephISO} -o /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo semanage fcontext -a -t container_file_t /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo restorecon -Rv /usr/share/ansible-runner-service/iso/rhceph-4.2-rhel-8-x86_64.iso
sudo chown -R ansible:ansible /usr/share/ceph-ansible
####################################################################################################

#######################################################################################
#WWWWWWWWWWWWWWWAAAAAAAAAAAAAAARRRRRRRRRRRRNIIIIIIIIIIIIIIIINNNNNNNNNNNNNNNNGGGGGGGGGGG
#commands below are to purge the cluster and the disks for a new installation
#cp infrastructure-playbooks/purge-container-cluster.yml .
#ansible-playbook -i hosts purge-container-cluster.yml
####error: ansible use can't use the sudo lvs!
#WWWWWWWWWWWWWWWAAAAAAAAAAAAAAARRRRRRRRRRRRNIIIIIIIIIIIIIIIINNNNNNNNNNNNNNNNGGGGGGGGGGG
for host in ${hosts}
do 
  ssh -o  StrictHostKeyChecking=no ansible@${host} /bin/bash << 'EOF'
  #!/bin/bash
 
  while read line 
  do 
    lvname=$(echo -n ${line} | awk '{print $1}') 
    vgname=$(echo $line | awk '{print $2}') 
    sudo lvremove -f $vgname/$lvname 
  done < <(sudo lvs | grep ^"[[:space:]]*osd-block" | grep -v rhel )
#done < <(sudo lvs | grep ^"[[:space:]]*ceph" | grep -v rhel )

  
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
    fi
  done < <(sudo pvs| awk '{print $1}' | tail -n +2)
  
  while read line
  do
    sudo wipefs -a /dev/$line
  done < <(sudo cat /proc/partitions | grep sd |grep -v "sda" | awk '{print $4}')
  
EOF
done
#########################################################################################
#hosts file needs to be modified based on environment 
cat > /usr/share/ceph-ansible/hosts << EOF
all:
  children:
    grafana-server:
      hosts:
        tceph-monitor: null
    mgrs:
      hosts:
        tceph01: null
        tceph02: null
        tceph03: null
    mons:
      hosts:
        tceph01: null
        tceph02: null
        tceph03: null
    osds:
      hosts:
        tceph01: null
        tceph02: null
        tceph03: null
    rgws:
      hosts:
        tceph01: null
        tceph02: null
        tceph03: null
#    rbdmirrors:
#      hosts:
#        tsceph01: null
#        tsceph02: null
EOF
#########################################################################################
#I used manual lvm and non-collocated methods and found the auto discovery has better best performace and configablity
#in future if nvme or PCIE SSDs or intel SSDs are available we can move wal and db to that partitions.
cd /usr/share/ceph-ansible/
echo "deprecation_warnings = False" >> /usr/share/ceph-ansible/ansible.cfg
cat >  /usr/share/ceph-ansible/group_vars/osds.yml << EOF
---
osd_auto_discovery: true
osd_objectstore: bluestore
osd_scenario: lvm
EOF

#just as sample for future use
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

#########################################################################################
#modify this file based on need. Most values are controlled by the variables but it worth check it all.
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

#to configure rbdmirroing if required
####################
#cat >  /usr/share/ceph-ansible/group_vars/rbdmirrors.yml << EOF
#ceph_rbd_mirror_configure: true
#ceph_rbd_mirror_pool: "rbd"
#ceph_rbd_mirror_mode: pool
#ceph_rbd_mirror_remote_cluster: "prod"
#ceph_rbd_mirror_remote_user: "admin"
#EOF
####################

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
#this part will do the whole installation
cd /usr/share/ceph-ansible
ansible-playbook -i hosts site-container.yml

#equip the ceph servers with ceph commands
#############################
for host in ${hosts}
do 
  ssh -o  StrictHostKeyChecking=no ansible@${host} sudo yum -y install ceph-common ceph-osd jq
done

#############################
#ceph config dump
#ceph osd pool autoscale-status
#ceph mgr module enable diskprediction_local
#ceph config set global device_failure_prediction_mode local
#ceph device ls
#ceph device predict-life-expectancy QEMU_QEMU_HARDDISK_2aea8810-7188-4a2b-9209-bfd7a3be58fd
#############################

#post setup configs
#############################
ceph -s
radosgw-admin user create --uid="s3user01" --display-name="s3user01" --caps="users=read,write; usage=read,write; buckets=read,write; zone=read,write" \
--access_key="12345" --secret="67890"
ceph osd crush rule create-replicated onssd default host ssd
ceph osd crush rule create-replicated onhdd default host hdd
source /etc/bash_completion.d/rbd
ceph osd pool create rbd 128 128 onssd
ceph osd pool application enable rbd rbd
rbd pool init rbd
ceph osd pool set rbd size 2
ceph osd pool set rbd min_size 1
ceph osd pool set default.rgw.buckets.data pg_num 128
ceph osd pool set default.rgw.buckets.data pgp_num 128

#these configs on client machine to use s3 
#I suppoesd the load balancer is already configured
#yum -y install s3cmd
#s3cmd --configure --access_key=12345 --secret_key=67890  --ssl --host=lb01.idm.mci.ir --host-bucket="lb01.idm.mci.ir/%(bucket)" --no-encrypt
#s3cmd mb s3://mybucket01
#s3cmd put --acl-public /etc/services s3://mybucket01
#s3cmd get s3://mybucket01/services
#############################
 
rados bench -p rbd 60 write --no-cleanup
rados bench -p rbd 30 rand -t 1024
rados bench -p rbd 30 seq -t 1024
rados cleanup -p rbd --run-name benchmark_last_metadata 

rbd create --size 1T image01
rbd map image01
#fio  --refill_buffers --filename=/dev/rbd0 --direct=1 --rw=write  --norandommap --randrepeat=0 --ioengine=libaio --bs=8K --rwmixread=100 --iodepth=32  --numjobs=8 --runtime=120 --group_reporting --name=rbd-test
rbd bench  --io-size 8K --pool rbd --image image01 --rw-mix-read 0 --io-type write --io-threads 128  --io-total 10G
rbd showmapped

#following is to configure s3cmd to use ldap service
#############################################################################################
#echo Iahoora@123 | kinit admin
rgwadmin=cephadmin
rgwpass=ahoora
ldapServer=$(ipa config-show | grep "IPA masters:" | awk -F: '{print $2}' | awk -F, '{print $1}')
ipa group-add rgw
echo ${rgwpass} | ipa user-add --first ceph --last admin ${rgwadmin} --password
ipa group-add-member  rgw --users ${rgwadmin}

domain=$(ipa config-show | grep "Certificate Subject base:" |  awk -F: '{print $2}' | awk -F= '{print $2}')
Domain=${domain,,}
array=(${Domain//./ })
for i in "${array[@]}" ; do out+="dc=$i," ; done
domain=${out::-1}
###########
#add following lines to ceph.config [global] section ,and restart the rgw pods
cat > t2 << EOF
rgw_ldap_uri = ldaps://${ldapServer}:636
rgw_ldap_binddn = "uid=${rgwadmin},cn=users,cn=accounts,${domain}"
rgw_ldap_secret = "/etc/ceph/bindpass"
rgw_ldap_searchdn = "cn=users,cn=accounts,${domain}"
rgw_search_filter  =  '(&(memberof=cn=rgw,cn=groups,cn=accounts,${domain}))'
rgw_ldap_dnattr = "uid"
rgw_s3_auth_use_ldap = true
EOF
###########
#this line contains the password of dn user
cat > /etc/ceph/bindpass << EOF
${rgwpass}
EOF

###########
ldapwhoami -H ldaps://${ldapServer}
ldapsearch -x -D "uid=${rgwadmin},cn=users,cn=accounts,${domain}" -W -H ldaps://${ldapServer} -b "cn=users,cn=accounts,${domain}" -s sub 'uid=${rgwadmin}'
###########
#the following command need to be issued in rgw client 
#you need to create a user in group rgw and write the user/pass here 
#the example here use the values of the binddn
rgwadmin=admin
rgwpass=Iahoora@123
cat > /etc/cephtoken << EOF
{
  "RGW_TOKEN": {
    "version": 1,
    "type": "ldap",
    "id": "${rgwadmin}",
    "key": "${rgwpass}"
  }
}
EOF
s3cmd --configure --access_key=$(cat /etc/cephtoken | base64 -w 0)  --secret_key=''  --ssl --host=lb01.${Domain} --host-bucket="lb01.${Domain}/%(bucket)" --no-encrypt

