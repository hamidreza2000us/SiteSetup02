sudo yum install -y gdeploy

if [ ! -f /root/.ssh/id_rsa ]
then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi
rootpass=Iahoora@123
nodeIP=1.1.1.1
sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${nodeIP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${nodeIP} hostname  &> /dev/null

rootpass=Iahoora@123
nodeIP=1.1.1.2
sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${nodeIP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${nodeIP} hostname  &> /dev/null

rootpass=Iahoora@123
nodeIP=1.1.1.3
sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${nodeIP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${nodeIP} hostname  &> /dev/null

	
cat > gd-ctdb.config << EOF

[hosts]
1.1.1.1
1.1.1.2
1.1.1.3

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
mount=/rhgs/brick1
virtualsize=1GB
lvtype=thinlv

[volume1]
action=create
volname=ctdb
transport=tcp
replica_count=3
force=yes
brick_dirs=/rhgs/ctdb/brick

[volume2]
action=create
volname=vol1
transport=tcp
replica_count=3
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
public_address=172.20.29.147/27 ens192
ctdb_nodes=172.20.29.141,172.20.29.142,172.20.29.143
volname=ctdb
smb_username=hamid
smb_password=ahoora
EOF

time gdeploy -c gd-ctdb.config
sleep 15
ctdb status
echo -e '' | smbclient -L localhost
#mount -vvvv -t cifs //172.20.29.147/gluster-vol1 /mnt -o user=hamid,pass=ahoora

#gluster volume set vol1 user.smb on