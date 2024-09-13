#This script must be run from the first server
##patch because of ansible version
#sed -i 's/^    lineinfile.*/    service: name=rpc-statd state=restarted/g'  /usr/share/gdeploy/playbooks/define_service_ports.yml
##sed -i "s/'^#STATD_PORT=.*' line='STATD_PORT=662'/'^#(STATD_PORT=.*)' line='\\\1' backrefs=yes/g" /usr/share/gdeploy/playbooks/define_service_ports.yml
kinit admin
nodes=3
read -rp "How many nodes do you want to configure: ($nodes): " choice; [[ -n "${choice}"  ]] &&  export nodes="$choice";

nodeName=()
for i in $(seq 0 $[$nodes-1])
do
    node=''
    read -rp "What is the DNS name of Server $i : " choice; [[ -n "${choice}"  ]] &&  export node="$choice";
    nodeName+=($node)
done
nodeNameString1=${nodeName[@]}
nodeNameString2=$(echo ${nodeNameString1// /,})
#echo -e ${nodeNameString1// /\\n} >> t3


nodeIP=()
for i in $(seq 0 $[$nodes-1])
do
    node=''
    read -rp "What is the VIP of Ganesha service node $i : " choice; [[ -n "${choice}"  ]] &&  export node="$choice";
    nodeIP+=($node)
done
nodeIPString1=${nodeIP[@]}
nodeIPString2=$(echo ${nodeIPString1// /,})
#echo -e ${nodeIPString1// /\\n} >> t3

nodePass=()
rootpass=Iahoora@123
for i in $(seq 0 $[$nodes-1])
do
    read -rp "What is root Password of server $i ($rootpass) : " choice; [[ -n "${choice}"  ]] &&  export rootpass="$choice";
    nodePass+=($rootpass)
done

diskName='/dev/sdb'
read -rp "What is the disk name to use ($diskName) : " choice; [[ -n "${choice}"  ]] &&  export diskName="$choice";
diskGroup=1
read -rp "What is the disk group ID to use ($diskGroup) : " choice; [[ -n "${choice}"  ]] &&  export diskGroup="$choice";
VIPDNS=gfs
read -rp "What is the dns name for cluster service ($VIPDNS) : " choice; [[ -n "${choice}"  ]] &&  export VIPDNS="$choice";

mkdir /usr/lib/tuned/rhgs-random-io
cat > /usr/lib/tuned/rhgs-random-io/tuned.conf << EOF
[main]
include=throughput-performance

[sysctl]
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
EOF

mkdir /usr/lib/tuned/rhgs-sequential-io
cat > /usr/lib/tuned/rhgs-sequential-io/tuned.conf << EOF
[main]
include=throughput-performance

[sysctl]
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10
EOF
tuned-adm profile rhgs-sequential-io



###################################################################################################

sudo yum install -y gdeploy

if [ ! -f /root/.ssh/id_rsa ]
then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi

for i in $(seq 0 $[$nodes-1])
do
  thisNodeIP=${nodeName[$i]}
  rootpass=${nodePass[$i]}
  sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${thisNodeIP}
  ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${thisNodeIP} hostname  &> /dev/null
  scp -r /usr/lib/tuned/rhgs-random-io ${thisNodeIP}:/usr/lib/tuned/
  scp -r /usr/lib/tuned/rhgs-sequential-io ${thisNodeIP}:/usr/lib/tuned/
  ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${thisNodeIP} hostname  &> /dev/null
  ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${thisNodeIP} yum -y install policycoreutils-python
done

echo '[hosts]' > gd-gan.config
echo -e ${nodeNameString1// /\\n} >> gd-gan.config
echo -e '' 	>> gd-gan.config
cat >> gd-gan.config << EOF

[tune-profile]
rhgs-sequential-io

[selinux]
yes

[disktype]
raid6

[diskcount]
12

[stripesize]
128

[yum]
action=install
repos=
packages=glusterfs-server,glusterfs-ganesha,policycoreutils-python,glusterfs-geo-replication
gpgcheck=no
update=no

[firewalld]
action=add
ports=111/tcp,2049/tcp,54321/tcp,5900/tcp,5900-6923/tcp,5666/tcp,16514/tcp
services=glusterfs,nlm,nfs,rpc-bind,high-availability,mountd,rquota

[service]
action=start
service=glusterd

[peer]
action=probe

[backend-setup]
devices=${diskName}
vgs=vg${diskGroup}
pools=pool${diskGroup}
lvs=lv${diskGroup}
mountpoints=/rhgs/brick${diskGroup}
brick_dirs=/rhgs/brick${diskGroup}/brick

[volume]
action=create
volname=vol${diskGroup}
replica=yes
replica_count=${nodes}
force=yes
#key=quota-deem-statfs,features.uss
#value=on,enable

[nfs-ganesha]
action=create-cluster
ha-name=ganesha-ha-360
cluster-nodes=${nodeNameString2}
vip=${nodeIPString2}
volname=vol${diskGroup}
ignore_ganesha_errors=no

[quota]
action=enable
volname=vol${diskGroup}

EOF

time gdeploy -c gd-gan.config

pcs status
showmount -e localhost
# mount -t nfs gfs.idm.mci.ir:/vol1 /mnt/ -o sec=krb5  -vvvvvvvvvv; umount /mnt

#VIPDNS=gfs
cat >> /etc/ganesha/ganesha.conf << EOF

NFS_KRB5
{
        PrincipalName = nfs ;
        KeytabPath = /etc/${VIPDNS}.keytab ;
        Active_krb5 = true ;
}
EOF

#################################################################


#echo "Iahoora@1234" | kinit admin
#debug variables
#nodeIP=(172.20.29.145 172.20.29.146 172.20.29.147)
#nodes=3
#nodeName=(gfs741 gfs742 gfs743)

ipa host-add ${VIPDNS}.$(hostname -d) --ip-address=${nodeIP[0]}
kdc=$(grep master_kdc /etc/krb5.conf | awk '{print $3}' | awk -F: '{print $1}')
ipa service-add nfs/${VIPDNS}.$(hostname -d)
ipa-getkeytab -s ${kdc} -p  nfs/${VIPDNS}.$(hostname -d) -k /etc/${VIPDNS}.keytab

#sed -i 's/SecType = "sys"/SecType = "krb5"/g' /var/run/gluster/shared_storage/nfs-ganesha/exports/export.vol${diskGroup}.conf
#sed -i 's/Squash="No_root_squash"/Squash="Root_squash"/g' /var/run/gluster/shared_storage/nfs-ganesha/exports/export.vol${diskGroup}.conf
#systemctl restart nfs-ganesha

for i in $(seq 1 $[$nodes-1])
do
   ipa dnsrecord-add $(hostname -d) ${VIPDNS} --a-ip-address=${nodeIP[$i]}
   ipa service-add-host nfs/${VIPDNS}.$(hostname -d)  --hosts=${nodeName[$i]}
   scp /etc/${VIPDNS}.keytab ${nodeName[$i]}:/etc/${VIPDNS}.keytab
   ssh ${nodeName[$i]} systemctl restart nfs-ganesha
done

mount -t glusterfs localhost:/vol${diskGroup} /mnt
mkdir /mnt/exports
chmod 777 /mnt/exports
umount /mnt

#ipa automountlocation-add #default
#ipa automountmap-add-indirect default auto.home --mount=/home/exports
#ipa automountkey-add default auto.home --key "*" --info "${VIPDNS}.idm.mci.ir:/vol${diskGroup}/&"



