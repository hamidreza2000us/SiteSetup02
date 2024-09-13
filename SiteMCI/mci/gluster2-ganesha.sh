#sudo subscription-manager unregister
#sudo subscription-manager unregister
#sudo subscription-manager register --org="MCI" --activationkey="kgluster"
#touch /etc/sysconfig/nfs
sudo yum install -y gdeploy
#patch because of ansible version
sed -i 's/^    lineinfile.*/    service: name=rpc-statd state=restarted/g'  /usr/share/gdeploy/playbooks/define_service_ports.yml
#sed -i "s/'^#STATD_PORT=.*' line='STATD_PORT=662'/'^#(STATD_PORT=.*)' line='\\\1' backrefs=yes/g" /usr/share/gdeploy/playbooks/define_service_ports.yml

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
	
#rm -rf /etc/ganesha/ganesha.conf

cat > gd-gan.config << EOF
[hosts]
gfs701
gfs702

[yum]
action=install
repos=
packages=glusterfs-server,glusterfs-ganesha
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
devices=sdb
vgs=vg1
pools=pool1
lvs=lv1
mountpoints=/rhgs/brick1
brick_dirs=/rhgs/brick1/brick

[volume]
action=create
volname=ganesha
replica=yes
replica_count=2
force=yes

[nfs-ganesha]
action=create-cluster
ha-name=ganesha-ha-360
cluster-nodes=gfs701,gfs702
vip=172.20.29.144,172.20.29.145
volname=ganesha
ignore_ganesha_errors=no

EOF

time gdeploy -c gd-gan.config