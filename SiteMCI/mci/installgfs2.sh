nodes=2
vcenter="rhvm.idm.mci.ir"
vcenteruser="Administrator@VSPHERE.LOCAL"
vcenterpass="Iahoora@123"
diskName='/dev/sdb'
rootpass=Iahoora@123

read -rp "How many nodes do you want to configure: ($nodes): " choice; [[ -n "${choice}"  ]] &&  export nodes="$choice";

nodeName=()
echo "For question below if you use DNS name make sure it is resolvable by all cluster members"
echo " "
for i in $(seq 0 $[$nodes-1])
do
    node=''
    read -rp "What is the DNS name OR IP address of Server $i : " choice; [[ -n "${choice}"  ]] &&  export node="$choice";
    nodeName+=($node)
done
nodeNameString1=${nodeName[@]}
nodeNameString2=$(echo ${nodeNameString1// /,})
#echo -e ${nodeNameString1// /\\n} >> t3

nodePass=()
for i in $(seq 0 $[$nodes-1])
do
    read -rp "What is root Password of server $i ($rootpass) : " choice; [[ -n "${choice}"  ]] &&  export rootpass="$choice";
    nodePass+=($rootpass)
done

read -rp "What is the FULL PATH of disk name to use ($diskName) : " choice; [[ -n "${choice}"  ]] &&  export diskName="$choice";
volCount=$(gluster volume list 2> /dev/null | wc -l)
[[ ${volCount} == 0 ]] && diskGroup=1 || diskGroup=$[${volCount} + 1]

###################################################################################################

haclusterPass=redhat
cat > /tmp/install-gfs.sh << EOF
yum install -y pcs fence-agents-all pacemaker  corosync-qdevice
yum install -y dlm lvm2-lockd gfs2-utils 
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload
systemctl enable --now pcsd
echo ${haclusterPass} | passwd --stdin hacluster
#becuase of a bug in corosync
yum update -y
sed -i 's/system_id_source = "none"/system_id_source = "uname"/g' /etc/lvm/lvm.conf

EOF

if [ ! -f /root/.ssh/id_rsa ]
then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi

yum -y install sshpass

for i in $(seq 0 $[$nodes-1])
do
  thisNodeIP=${nodeName[$i]}
  rootpass=${nodePass[$i]}
  sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${thisNodeIP}
  ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${thisNodeIP} hostname  &> /dev/null
  scp -i /root/.ssh/id_rsa /tmp/install-gfs.sh root@${thisNodeIP}:/tmp
done

for i in $(seq 0 $[$nodes-1])
do
    thisNodeIP=${nodeName[$i]}
	ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${thisNodeIP} bash /tmp/install-gfs.sh
done

#echo ${nodeNameString1}
pcs cluster auth ${nodeNameString1} -u hacluster -p ${haclusterPass}
pcs cluster setup --name mycluster --start ${nodeNameString1} \
 --wait_for_all=1  --auto_tie_breaker=1  --last_man_standing=1

pcs stonith create vmfence fence_vmware_rest \
ipaddr=${vcenter} ssl_insecure=1 \
login=${vcenteruser} \
passwd=${vcenterpass}

pcs resource create dlm ocf:pacemaker:controld \
 op monitor interval=30s on-fail=fence --group=lock_group --wait=30
pcs resource create lvmlockd ocf:heartbeat:lvmlockd \
 op monitor interval=30s on-fail=fence --group=lock_group --wait=30
pcs resource clone lock_group interleave=true --wait=30
sleep 10
pcs status --full
#sleep 30
#pcs status --full
#cat > /tmp/test << EOF
#wipefs -a ${diskName}

vgcreate --shared lvmsharedvg ${diskName}

for i in $(seq 0 $[$nodes-1])
do
    thisNodeIP=${nodeName[$i]}
	ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${thisNodeIP} vgchange --lock-start lvmsharedvg
	sleep 3
	
done

lvcreate --activate y -l 100%Free -n lv1 lvmsharedvg
udevadm settle
partprobe
#lvs

pcs resource create sharedlv1 LVM-activate \
 vgname=lvmsharedvg lvname=lv1 activation_mode=shared vg_access_mode=lvmlockd \
 --group=LVMshared_group --wait=30
pcs resource clone LVMshared_group interleave=true --wait=30
pcs constraint order start \
 lock_group-clone then LVMshared_group-clone --wait=30
pcs constraint colocation add \
 LVMshared_group-clone with lock_group-clone --wait=30

sleep 10
mkfs.gfs2 -t mycluster:gfs01  -j $nodes -J 128  /dev/lvmsharedvg/lv1 -O
pcs resource create clusterfs Filesystem \
 device=/dev/lvmsharedvg/lv1 directory=/mnt fstype=gfs2 \
 op monitor on-fail=fence --group=LVMshared_group --wait=30
 
#pcs property set no-quorum-policy=freeze
#gfs2_edit -p journals /dev/lvmsharedvg/lv1
#gfs2_jadd -j 2 -J 256 /dev/lvmsharedvg/lv1
#gfs2_grow /dev/lvmsharedvg/lv1
#tunegfs2 -l /dev/lvmsharedvg/lv1
#tunegfs2 -o locktable=mycluster:gfs01 /dev/lvmsharedvg/lv1

#EOF



