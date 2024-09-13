systemctl stop glusterd
killall glusterfs
killall glusterfsd

yum install -y glusterfs-ganesha
firewall-cmd --add-service=high-availability \
--add-service=nfs --add-service=rpc-bind --add-service=mountd --permanent
firewall-cmd --reload


#one server
#cp /etc/ganesha/ganesha-ha.conf{.sample,}
cat > /etc/ganesha/ganesha-ha.conf << EOF
HA_NAME="gls-ganesha"
HA_VOL_SERVER="srvrh801.idm.mci.ir"
HA_CLUSTER_NODES="srvrh801.idm.mci.ir,srvrh802.idm.mci.ir"
VIP_srvrh801_idm_mci_ir="172.20.29.136"
VIP_srvrh802_idm_mci_ir="172.20.29.137"
EOF

scp /etc/ganesha/ganesha-ha.conf srvrh802:/etc/ganesha/
systemctl enable pacemaker pcsd
systemctl start pcsd
echo redhat | passwd --stdin hacluster
pcs host auth -u hacluster -p redhat srvrh802.idm.mci.ir srvrh801.idm.mci.ir
pcs cluster setup my_cluster --start  srvrh802.idm.mci.ir srvrh801.idm.mci.ir
pcs cluster enable --all
pcs cluster status

ssh-keygen -f /var/lib/glusterd/nfs/secret.pem -t rsa -N ''
scp /var/lib/glusterd/nfs/secret.pem* srvrh801:/var/lib/glusterd/nfs/
ssh-copy-id -i /var/lib/glusterd/nfs/secret.pem.pub root@srvrh801
ssh-copy-id -i /var/lib/glusterd/nfs/secret.pem.pub root@srvrh802

 gluster volume set all cluster.enable-shared-storage enable
 cp /etc/ganesha/ganesha.conf /run/gluster/shared_storage
 
 
