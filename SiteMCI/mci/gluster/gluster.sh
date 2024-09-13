

subscription-manager unregister
subscription-manager register --org="MCI" --activationkey="kgluster"
yum install -y glusterfs-server
#tuned-adm profile throughput-performance
#yum install -y redhat-storage-server
#tuned-adm profile rhgs-random-io

systemctl enable --now glusterd
firewall-cmd --add-service=glusterfs --permanent
firewall-cmd --reload

#just one server
gluster peer probe srvrh802.idm.mci.ir
#gluster peer detach srvrh802.idm.mci.ir
gluster peer status
gluster pool list

dev=sdb
pool=pool01
vol=vol01
pvcreate /dev/${dev}
vgcreate vg_bricks /dev/${dev}
#vgextend vg_bricks /dev/${dev}
lvcreate -L 10G -T vg_bricks/${pool}
lvcreate -V 2G -T vg_bricks/${pool} -n ${vol}
mkfs -t xfs -i size=512 /dev/vg_bricks/${vol}
mkdir -p /bricks/${vol}
echo "/dev/vg_bricks/${vol} /bricks/${vol} xfs defaults 1 2" >> /etc/fstab
mount /bricks/${vol}
mkdir /bricks/${vol}/brick
semanage fcontext -a -t glusterd_brick_t /bricks/${vol}/brick
restorecon -Rv /bricks/${vol}/brick


#just one server
volume=vol01
#gluster volume create ${volume} srvrh801:/bricks/${vol}/brick  srvrh802:/bricks/${vol}/brick
gluster volume create ${volume} srvrh801:/rhgs/brick1/b1  srvrh802:/rhgs/brick1/b1
gluster volume start ${volume}
gluster volume status ${volume}
gluster volume info ${volume}

#on client
yum -y install glusterfs-fuse
mkdir /mnt/firstvol
mount -t glusterfs srvrh801:firstvol /mnt/firstvol
echo "srvrh801:firstvol /mnt/firstvol glusterfs _netdev,backup-volfile-servers=srvrh802 0 0" >> /etc/fstab