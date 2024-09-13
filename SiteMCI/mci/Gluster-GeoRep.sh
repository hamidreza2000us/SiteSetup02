#systemctl stop glusterd
#pkill gluster
#pkill glusterd
#yum -y install glusterfs-geo-replication
#systemctl start glusterd

MasterHost='gfs731'
read -rp "What is the DNS name of Master Host ($MasterHost) : " choice; [[ -n "${choice}"  ]] &&  export MasterHost="$choice";

MasterVol='vol1'
read -rp "What is the Master Host Volume to sync ($MasterVol) : " choice; [[ -n "${choice}"  ]] &&  export MasterVol="$choice";

nodes=3
read -rp "How many slave nodes you have ($nodes): " choice; [[ -n "${choice}"  ]] &&  export nodes="$choice";

nodeName=()
for i in $(seq 0 $[$nodes-1])
do
    node=''
    read -rp "What is the DNS name of slave node $i : " choice; [[ -n "${choice}"  ]] &&  export node="$choice";
    nodeName+=($node)
done
nodeNameString1=${nodeName[@]}
nodeNameString2=$(echo ${nodeNameString1// /,})

SlaveVol='vol1'
read -rp "What is the Slave Volume name ($SlaveVol) : " choice; [[ -n "${choice}"  ]] &&  export SlaveVol="$choice";


nodePass=()
rootpass=Iahoora@123
for i in $(seq 0 $[$nodes-1])
do
    read -rp "What is root Password of Slave node $i ($rootpass) : " choice; [[ -n "${choice}"  ]] &&  export rootpass="$choice";
    nodePass+=($rootpass)
done


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

cat > gd-georep.conf << EOF
[hosts]
${MasterHost}

[geo-replication]
action=create
georepuser=georep
mastervol=${MasterHost}:${MasterVol}
slavevol=${nodeName[0]}:${SlaveVol}
slavenodes=${nodeNameString2}
force=yes
start=yes
EOF

gdeploy -c gd-georep.conf

