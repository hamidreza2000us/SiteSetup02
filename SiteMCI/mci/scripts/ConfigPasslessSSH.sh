#!/bin/bash


read -rp "What is the IP of the This node in the cluster (${node1IP}) : " choice; [[ -n "${choice}"  ]] &&  export node1IP="$choice";
read -rp "What is the Oracle User Password of the THIS node (${node1oraclepass}) : " choice; [[ -n "${choice}"  ]] &&  export node1oraclepass="$choice";
read -rp "What is the Grid User Password of the THIS node (${node1gridpass}) : " choice; [[ -n "${choice}"  ]] &&  export node1gridpass="$choice";
read -rp "What is the root User Password of the THIS node in the cluster (${node1rootpass}) : " choice; [[ -n "${choice}"  ]] &&  export node1rootpass="$choice";
read -rp "What is the IP of the OTHER node in the cluster (${node2IP}) : " choice; [[ -n "${choice}"  ]] &&  export node2IP="$choice";
read -rp "What is the Oracle User Password of the OTHER node in the cluster (${node2oraclepass}) : " choice; [[ -n "${choice}"  ]] &&  export node2oraclepass="$choice";
read -rp "What is the Grid User Password of the OTHER node in the cluster (${node2gridpass}) : " choice; [[ -n "${choice}"  ]] &&  export node2gridpass="$choice";
read -rp "What is the root User Password of the OTHER node in the cluster (${node2rootpass}) : " choice; [[ -n "${choice}"  ]] &&  export node2rootpass="$choice";

#root config
if [ ! -f /root/.ssh/id_rsa ]
then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi
sshpass -p "${node1rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${node1IP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${node1IP} hostname  &> /dev/null

sshpass -p "${node2rootpass}" ssh-copy-id -o StrictHostKeyChecking=false -i /root/.ssh/id_rsa.pub ${node2IP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false ${node2IP} hostname  &> /dev/null

#grid config
if [ ! -f /home/grid/.ssh/id_rsa ]
then
        sudo -u grid mkdir -p /home/grid/.ssh
        sudo -u grid ssh-keygen -t rsa -N '' -f /home/grid/.ssh/id_rsa
fi
sudo -u grid sshpass -p ${node1gridpass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/grid/.ssh/id_rsa.pub ${node1IP}
sudo -u grid ssh -o StrictHostKeyChecking=false grid@${node1IP} hostname  &> /dev/null

sudo -u grid sshpass -p ${node2gridpass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/grid/.ssh/id_rsa.pub grid@${node2IP}
sudo -u grid ssh -o StrictHostKeyChecking=false grid@${node2IP} hostname  &> /dev/null

#oracle config
if [ ! -f /home/oracle/.ssh/id_rsa ]
then
        sudo -u oracle mkdir -p /home/oracle/.ssh
        sudo -u oracle ssh-keygen -t rsa -N '' -f /home/oracle/.ssh/id_rsa
fi
sudo -u oracle sshpass -p ${node1oraclepass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/oracle/.ssh/id_rsa.pub ${node1IP}
sudo -u oracle ssh -o StrictHostKeyChecking=false ${node1IP} hostname  &> /dev/null

sudo -u oracle sshpass -p ${node2oraclepass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/oracle/.ssh/id_rsa.pub ${node2IP}
sudo -u oracle ssh -o StrictHostKeyChecking=false ${node2IP} hostname  &> /dev/null

##########################not tested#####################################


cat > /root/PasslessSSH.sh << EOF
#root config
if [ ! -f /root/.ssh/id_rsa ]
then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi
sshpass -p ${node2rootpass} ssh-copy-id -o StrictHostKeyChecking=false  -i /root/.ssh/id_rsa.pub ${node2IP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false {node2IP} hostname  &> /dev/null

sshpass -p ${node1rootpass} ssh-copy-id -o StrictHostKeyChecking=false  -i /root/.ssh/id_rsa.pub ${node1IP}
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=false {node1IP} hostname  &> /dev/null
############################
#grid config
if [ ! -f /home/grid/.ssh/id_rsa ]
then
        sudo -u grid mkdir -p /home/grid/.ssh
        sudo -u grid ssh-keygen -t rsa -N '' -f /home/grid/.ssh/id_rsa
fi
sudo -u grid sshpass -p ${node2gridpass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/grid/.ssh/id_rsa.pub grid@${node2IP}
sudo -u grid ssh -o StrictHostKeyChecking=false grid@${node2IP} hostname  &> /dev/null

sudo -u grid sshpass -p ${node1gridpass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/grid/.ssh/id_rsa.pub grid@${node1IP}
sudo -u grid ssh -o StrictHostKeyChecking=false grid@${node1IP} hostname  &> /dev/null

#oracle config
if [ ! -f /home/oracle/.ssh/id_rsa ]
then
        sudo -u oracle mkdir -p /home/oracle/.ssh
        sudo -u oracle ssh-keygen -t rsa -N '' -f /home/oracle/.ssh/id_rsa
fi
sudo -u oracle sshpass -p ${node2oraclepass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/oracle/.ssh/id_rsa.pub oracle@${node2IP}
sudo -u oracle ssh -o StrictHostKeyChecking=false oracle@${node2IP} hostname  &> /dev/null

sudo -u oracle sshpass -p ${node1oraclepass} ssh-copy-id -o StrictHostKeyChecking=false  -i /home/oracle/.ssh/id_rsa.pub oracle@${node1IP}
sudo -u oracle ssh -o StrictHostKeyChecking=false oracle@${node1IP} hostname  &> /dev/null

EOF


sshpass -p ${node2rootpass} scp /root/PasslessSSH.sh ${node2IP}:/root/PasslessSSH.sh
sshpass -p ${node2rootpass} ssh ${node2IP} bash /root/PasslessSSH.sh

sshpass -p ${node2rootpass} ssh ${node2IP} rm -rf /root/PasslessSSH.sh
rm -rf /home/oracle/PasslessSSH.sh

grep $(hostname -s) /etc/hosts > /tmp/host1
ssh ${node2IP}  'grep $(hostname -s) /etc/hosts > /tmp/host2'
scp /tmp/host1 ${node2IP}:/tmp/host1 
scp ${node2IP}:/tmp/host2 /tmp/host2
cat /tmp/host2 >> /etc/hosts
cat /etc/hosts | sort -k2 | uniq | grep -v "^$" > /tmp/hosts
cat /tmp/hosts > /etc/hosts
ssh ${node2IP}  'cat /tmp/host1 >> /etc/hosts'
ssh ${node2IP}  'cat /etc/hosts | sort -k2 | uniq | grep -v "^$" > /tmp/hosts'
ssh ${node2IP}  'cat /tmp/hosts > /etc/hosts'
rm -rf /tmp/host2 /tmp/hosts
ssh ${node2IP}  'rm -rf  /tmp/host1 /tmp/hosts'
#Fixme: to delete duplicated host entries
#sed -i  "$(hostname -s)/d" /etc/hosts
#sed -i  "$(hostname -s)/d" /etc/hosts
