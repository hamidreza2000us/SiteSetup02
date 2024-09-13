##patch because of ansible version
#sed -i 's/^    lineinfile.*/    service: name=rpc-statd state=restarted/g'  /usr/share/gdeploy/playbooks/define_service_ports.yml
##sed -i "s/'^#STATD_PORT=.*' line='STATD_PORT=662'/'^#(STATD_PORT=.*)' line='\\\1' backrefs=yes/g" /usr/share/gdeploy/playbooks/define_service_ports.yml

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
    read -rp "What is the VIP $i : " choice; [[ -n "${choice}"  ]] &&  export node="$choice";
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
diskGroup=2
read -rp "What is the disk group ID to use ($diskGroup) : " choice; [[ -n "${choice}"  ]] &&  export diskGroup="$choice";

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
done

echo '[hosts]' > gd-gan.config
echo -e ${nodeNameString1// /\\n} >> gd-gan.config
echo -e '' 	>> gd-gan.config
cat >> gd-gan.config << EOF


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
devices=${diskName}
vgs=vg${diskGroup}
pools=pool${diskGroup}
lvs=lv${diskGroup}
mountpoints=/rhgs/brick${diskGroup}
brick_dirs=/rhgs/brick${diskGroup}/brick

[volume]
action=create
volname=ganesha
replica=yes
replica_count=${nodes}
force=yes

[nfs-ganesha]
action=create-cluster
ha-name=ganesha-ha-360
cluster-nodes=${nodeNameString2}
vip=${nodeIPString2}
volname=ganesha
ignore_ganesha_errors=no

EOF

time gdeploy -c gd-gan.config

pcs status
showmount -e localhost
#mount -vvv -t nfs 172.20.29.147:/ganesha /mnt


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


ipa automountlocation-add default
ipa automountmap-add-indirect default auto.home --mount=/home
ipa automountkey-add default auto.home --key "*" --info "gfs.idm.mci.ir:/vol1/&"

	  
