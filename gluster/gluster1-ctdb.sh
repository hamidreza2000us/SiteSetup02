sudo yum install -y gdeploy

if [ ! -f /root/.ssh/id_rsa ]
then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi
node1rootpass=Iahoora@123
node1IP=gfs701
sshpass -p "${node1rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${node1IP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${node1IP} hostname  &> /dev/null

node2rootpass=Iahoora@123
node2IP=gfs702
sshpass -p "${node2rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${node2IP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${node2IP} hostname  &> /dev/null
	
cat > gd-ctdb.config << EOF

[hosts]
172.20.29.141
172.20.29.142

[yum]
action=install
repolist=
gpgcheck=no
update=no
packages=samba,samba-client,glusterfs-server,ctdb

[firewalld]
action=add
ports=54321/tcp,5900/tcp,5900-6923/tcp,5666/tcp,4379/tcp
services=glusterfs,samba,high-availability

[pv1]
action=create
devices=sdb

[vg1]
action=create
vgname=vg1
pvname=sdb

[lv0]
action=create
poolname=pool1
vgname=vg1
lvtype=thinpool

[lv1]
action=create
lvname=lv_ctdb
vgname=vg1
poolname=pool1
mount=/rhgs/ctdb
virtualsize=1GB
lvtype=thinlv

[lv2]
action=create
lvname=lv1
vgname=vg1
poolname=pool1
mount=/rhgs/ctdb
virtualsize=1GB
lvtype=thinlv

[volume1]
action=create
volname=ctdb1
transport=tcp
replica_count=2
force=yes
brick_dirs=/rhgs/ctdb/brick

[volume2]
action=create
volname=vol1
transport=tcp
replica_count=2
force=yes
smb=yes
smb_mountpoint=/mnt/smb
smb_username=hamid
brick_dirs=/rhgs/brick1/brick

[volume]
volname=vol1
action=set
key=user.smb
value=on

[ctdb]
action=setup
public_address=172.20.29.146/27 ens192
volname=ctdb1
smb_username=hamid
smb_password=ahoora
EOF

time gdeploy -c gd-ctdb.config

#gluster volume set vol1 user.smb on