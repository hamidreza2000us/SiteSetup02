##patch because of ansible version
#sed -i 's/^    lineinfile.*/    service: name=rpc-statd state=restarted/g'  /usr/share/gdeploy/playbooks/define_service_ports.yml
##sed -i "s/'^#STATD_PORT=.*' line='STATD_PORT=662'/'^#(STATD_PORT=.*)' line='\\\1' backrefs=yes/g" /usr/share/gdeploy/playbooks/define_service_ports.yml

sudo yum install -y gdeploy

if [ ! -f /root/.ssh/id_rsa ]
then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi
rootpass=Iahoora@123
nodeIP=gfs714
sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${nodeIP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${nodeIP} hostname  &> /dev/null

rootpass=Iahoora@123
nodeIP=gfs715
sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${nodeIP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${nodeIP} hostname  &> /dev/null

rootpass=Iahoora@123
nodeIP=gfs716
sshpass -p "${rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${nodeIP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${nodeIP} hostname  &> /dev/null


	
cat > gd-gan.config << EOF
[hosts]
gfs714
gfs715
gfs716

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
devices=sdc
vgs=vg2
pools=pool2
lvs=lv2
mountpoints=/rhgs/brick2
brick_dirs=/rhgs/brick2/brick

[volume]
action=create
volname=ganesha
replica=yes
replica_count=3
force=yes

[nfs-ganesha]
action=create-cluster
ha-name=ganesha-ha-360
cluster-nodes=gfs701,gfs702,gfs703
vip=172.20.29.147,172.20.29.148,172.20.29.149
volname=ganesha
ignore_ganesha_errors=no

EOF

time gdeploy -c gd-gan.config

pcs status
showmount -e localhost
mount -vvv -t nfs 172.20.29.147:/ganesha /mnt


cat >> /etc/ganesha/ganesha.conf << EOF

NFS_KRB5
{
        PrincipalName = nfs ;
        KeytabPath = /etc/krb5.keytab ;
        Active_krb5 = true ;
}
EOF

sed -i 's/SecType = "sys"/SecType = "krb5"/g' /var/run/gluster/shared_storage/nfs-ganesha/exports/export.ganesha.conf
sed -i 's/Squash="No_root_squash"/Squash="Root_squash"/g' /var/run/gluster/shared_storage/nfs-ganesha/exports/export.ganesha.conf


	  
