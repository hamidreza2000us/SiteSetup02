########################################################################################
cat > setupTeamInterface.sh << 'EOF'
ip a sh
read -rp "What is the name of the Team Interface: " choice; [[ -n "${choice}"  ]] &&  export TeamName="$choice";
read -rp "What is the name of first Slave Interface: " choice; [[ -n "${choice}"  ]] &&  export slave0="$choice";
read -rp "What is the name of Second Slave Interface: " choice; [[ -n "${choice}"  ]] &&  export slave1="$choice";
read -rp "What is the IP address of this Team Interface: " choice; [[ -n "${choice}"  ]] &&  export IP="$choice";
read -rp "What is the netmask of this Team Interface: " choice; [[ -n "${choice}"  ]] &&  export MASK="$choice";
read -rp "If this Interface is the primary GW please set the gateway: " choice; [[ -n "${choice}"  ]] &&  export GW="$choice";
echo "So we will set a Team interface ($TeamName) with two slave ($slave0,$slave1)"
echo "and set the IP of $IP/$MASK which will have a gateway of $GW  "
echo "If this is correct Please select Y"
while true; do
    read -p "Will you continue? [Y/N]" yn
    case $yn in
        [Yy] )
            break
            ;;
        [Nn] )
            exit
            break
            ;;
    esac
done


echo 'kernel.printk=2 4 1 7' >> /etc/sysctl.conf
sysctl -p > /dev/null
if [[ $(ip l sh | grep -q ${slave0}; echo $?) != 0  ]] ; then echo "incorrect interface name" ; exit; fi
if [[ $(ip l sh | grep -q ${slave1}; echo $?) != 0  ]] ; then echo "incorrect interface name" ; exit; fi

con=$(nmcli -t dev | grep "^${slave0}:" | awk -F: '{print $4}')
echo "con: ${con}" 
isteam=$(nmcli con sh ${con} | grep connection.slave-type | awk -F: '{print $2}')
echo "isteam: ${isteam}"
if [  ${isteam##*( )} == 'team' ]
then
  master=$(nmcli con sh ${con} | grep connection.master | awk -F: '{print $2}')
  for connection in $(nmcli -t  con sh | grep ${master##*( )} | grep ":team:" | awk -F: '{print $2}' )
  do
    nmcli con down  ${connection}
    nmcli con del  ${connection}
  done
fi
for connection in $(nmcli -t con sh | awk -F: '{print $2}') 
do 
  int=$(nmcli con sh $connection | grep connection.interface-name  | awk -F: '{print $2}') 
  if [ ${int##*( )} == ${slave0} ]
  then 
    nmcli con del ${connection}
  fi
done


con=$(nmcli -t dev | grep "^${slave1}:" | awk -F: '{print $4}')
isteam=$(nmcli con sh ${con} | grep connection.slave-type | awk -F: '{print $2}')
if [ ${isteam##*( )} == 'team' ]
then
  master=$(nmcli con sh ${con} | grep connection.master | awk -F: '{print $2}')
  for connection in $(nmcli -t  con sh | grep ${master##*( )} | grep ":team:" | awk -F: '{print $2}')
  do
    nmcli con down  ${connection}
    nmcli con del  ${connection}
  done
fi

for connection in $(nmcli -t con sh | awk -F: '{print $2}') 
do 
  int=$(nmcli con sh $connection | grep connection.interface-name  | awk -F: '{print $2}') 
  if [ ${int##*( )} == ${slave1} ]
  then 
    nmcli con del ${connection}
  fi
done

for connection in $(nmcli -f UUID,TYPE,DEVICE con sh | grep "team" | grep "\--" | awk  '{print $1}')
do
  nmcli con del ${connection}
done  

nmcli con reload
if [ -z "${GW}" ]
then
  nmcli con add con-name ${TeamName} type team ifname ${TeamName} team.runner lacp ipv4.method manual ipv4.addresses ${IP}/${MASK} 
else
  nmcli con add con-name ${TeamName} type team ifname ${TeamName} team.runner lacp ipv4.method manual ipv4.addresses ${IP}/${MASK} ipv4.gateway ${GW}
fi
nmcli con add con-name ${TeamName}-${slave1} ifname ${slave1} type team-slave master ${TeamName}
nmcli con add con-name ${TeamName}-${slave0} ifname ${slave0} type team-slave master ${TeamName}
nmcli con down "${TeamName}-${slave0}"
nmcli con down "${TeamName}-${slave1}"
nmcli con down "${TeamName}"
nmcli con reload
nmcli con up ${TeamName}-${slave0}
nmcli con up ${TeamName}-${slave1}
nmcli con up ${TeamName}
nmcli con sh
EOF
bash setupTeamInterface.sh