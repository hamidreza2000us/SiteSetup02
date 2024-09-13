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


nodePubIP=()
for i in $(seq 0 $[$nodes-1])
do
    node=''
    read -rp "What is the Public IP of Server $i : " choice; [[ -n "${choice}"  ]] &&  export node="$choice";
    nodePubIP+=($node)
done
nodePubIPString1=${nodePubIP[@]}
nodePubIPString2=$(echo ${nodePubIPString1// /,})
#echo -e ${nodeNameString1// /\\n} >> t3

#nodeIP=()
#for i in $(seq 0 $[$nodes-1])
#do
    node=''
    read -rp "What is the CTDB VIP/Subnet : " choice; [[ -n "${choice}"  ]] &&  export node="$choice";
#    nodeIP+=($node)
#done
nodeIPString1=$node
#nodeIPString2=$(echo ${nodeIPString1// /,})
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
ip a sh
read -rp "What is the name of Public Interface for CTDB ($INTName) : " choice; [[ -n "${choice}"  ]] &&  export INTName="$choice";
subnet=$(ip r sh | grep ens192 | grep link |  awk '{print $1}')

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

echo '[hosts]' > gd-ctdb.config
echo -e ${nodeNameString1// /\\n} >> gd-ctdb.config
echo -e '' 	>> gd-ctdb.config
cat >> gd-ctdb.config << EOF

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


[backend-setup]
devices=${diskName}
vgs=vg${diskGroup}
pools=pool${diskGroup}
lvs=lv${diskGroup}
mountpoints=/rhgs/brick${diskGroup}
brick_dirs=/rhgs/brick${diskGroup}/brick

[volume1]
action=create
volname=ctdb
transport=tcp
replica=yes
replica_count=$nodes
force=yes
brick_dirs=/rhgs/ctdb/brick

[volume2]
action=create
volname=vol${diskGroup}
transport=tcp
replica=yes
replica_count=$nodes
force=yes
smb=yes
smb_mountpoint=/mnt/smb
smb_username=hamid
brick_dirs=/rhgs/brick${diskGroup}/brick

[volume]
volname=vol${diskGroup}
action=set
key=user.smb
value=on

[ctdb]
action=setup
public_address=${nodeIPString1} ${INTName}
ctdb_nodes=${nodePubIPString2}
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