#################functions#################
removeInactiveCon() {
con=$(nmcli -t -f uuid,state,active con show | grep "no$" | awk -F: '{print $1}')
for connection in $con
  do
    nmcli con del  ${connection}
  done
}

removeInt() {
ifname=$1
IP=$2

#1-remove every connection linked this interface
for connection in $(nmcli -t con sh | awk -F: '{print $2}')
do
  int=$(nmcli con sh $connection | grep connection.interface-name  | awk -F: '{print $2}')
  if [ ${int##*( )} == ${ifname} ]
  then
    nmcli con del ${connection}
  fi
done

#3-remove any other interface using the same IP
int=$(ip -br -4 a sh | grep $IP | awk '{print $1}')
for interface in ${int}
do
        con=$(nmcli -t dev | grep "^${interface}:" | awk -F: '{print $4}')
        isteam=$(nmcli con sh ${con} | grep connection.slave-type | awk -F: '{print $2}')
        if [  "${isteam##*( )}" == 'team' ] || [  "${isteam##*( )}" == 'bond' ]
        then
                master=$(nmcli con sh ${con} | grep connection.master | awk -F: '{print $2}')
                for connection in $(nmcli -t  con sh | grep ${master##*( )} | grep -E ":team:|:bond:" | awk -F: '{print $2}' )
                do
                        nmcli con down  ${connection}
                        nmcli con del  ${connection}
                done
        else
                nmcli con down  ${con}
                nmcli con del  ${con}
        fi
done
removeInactiveCon
nmcli con reload
}

setSingleIF() {
ifname=$1
IP=$2
MASK=$3
GW=$4
DNS1=$5
DNS2=$6
DNSQuery=''
if [ ! -z "${DNS1}" ]
then
  DNSQuery="ipv4.dns ${DNS1}"
  if [ ! -z "${DNS2}" ]; then DNSQuery="${DNSQuery},${DNS2}"; fi
fi
if [[ $(ip l sh | grep -q ${ifname}; echo $?) != 0  ]] ; then echo "incorrect interface name" ; exit; fi

removeInt $ifname $IP

if [ -z "${GW}" ]
then
  nmcli con add con-name ${ifname} type ethernet ifname ${ifname} ipv4.method manual ipv4.addresses ${IP}/${MASK}
else
  nmcli con add con-name ${ifname} type ethernet ifname ${ifname} ipv4.method manual ipv4.addresses ${IP}/${MASK} ipv4.gateway ${GW} ${DNSQuery}
fi

}

setTeamIF() {
TeamName=$1
slave0=$2
slave1=$3
IP=$4
MASK=$5
GW=$6
DNS1=$7
DNS2=$8
DNSQuery=''
if [ ! -z "${DNS1}" ]
then
  DNSQuery="ipv4.dns ${DNS1}"
  if [ ! -z "${DNS2}" ]; then DNSQuery="${DNSQuery},${DNS2}"; fi
fi

if [[ $(ip l sh | grep -q ${slave0}; echo $?) != 0  ]] ; then echo "incorrect interface name" ; exit; fi
if [[ $(ip l sh | grep -q ${slave1}; echo $?) != 0  ]] ; then echo "incorrect interface name" ; exit; fi

removeInt $slave0 $IP
removeInt $slave1 $IP

if [ -z "${GW}" ]
then
  nmcli con add con-name ${TeamName} type team ifname ${TeamName} team.runner lacp ipv4.method manual ipv4.addresses ${IP}/${MASK}
else
  nmcli con add con-name ${TeamName} type team ifname ${TeamName} team.runner lacp ipv4.method manual ipv4.addresses ${IP}/${MASK} ipv4.gateway ${GW} ${DNSQuery}
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
}

NM2CIDR() {
#function returns prefix for given netmask in arg1
 ipcalc -p 1.1.1.1 $1 | sed -n 's/^PREFIX=\(.*\)/\1/p' 2> /dev/null
}
#####################################
file=/tmp/vars.sh
prompt=true
echo "By default we are reading the default IPs from the file /tmp/NISR"
echo "If this procedure has already run we may saved your preferences in /tmp/vars.sh"
if [ -f $file ]
then
        source $file
        echo "Following Value is already set..."
        echo -e "Type:\t\t\tIP Address\t\t\tGateway\t\tInterfaces";
        echo -e "Service:\t\t${SIP1} \t${SGW1} \t${SIF[@]}";
        echo -e "Private1:\t\t${PIP11} \t${PGW11} \t${P1IF[@]}";
        echo -e "Private2:\t\t${PIP12} \t${PGW11} \t${P2IF[@]}";
        echo -e "Management:\t\t${MIP1} \t${MGW1} \t${MIF[@]}";
        echo -e "Backup:    \t\t${BIP1} \t${BGW1} \t${BIF[@]}";
        echo -e "DNS:    \t\t${DNS1} \t${DNS2} ";
        echo ""
        echo -e "SCAN IPs are: \t\t$SCIP1,$SCIP2,$SCIP3";
        echo ""

        while true; do
                read -p "Do you want to keep these values? [Y/N]" yn
                case $yn in
                        [Yy] )
                                prompt=false
                                break
                                ;;
                        [Nn] )
                                prompt=true
                                break
                                ;;
                esac
        done
fi

if [ $prompt == true ]
then
        configFile=/tmp/NISR
        if [ -f $configFile ]
        then
                hostname=$(hostname -s)
                SVCName=${hostname::-1}
                SIP1=$(grep "${hostname}[[:space:]]" $configFile | awk '{print $3"/"$4}')
                SGW1=$(grep "${hostname}[[:space:]]" $configFile | awk '{print $5}')
                VIP1=$(grep "${hostname}-vip" $configFile | awk '{print $3}')
                PIP11=$(grep "${hostname}-prv1" $configFile | awk '{print $3"/"$4}')
                PGW11=$(grep "${hostname}-prv1" $configFile | awk '{print $5}')
                PIP12=$(grep "${hostname}-prv2" $configFile | awk '{print $3"/"$4}')
                PGW12=$(grep "${hostname}-prv2" $configFile | awk '{print $5}')
                MIP1=$(grep "${hostname}-mgmt" $configFile | awk '{print $3"/"$4}')
                MGW1=$(grep "${hostname}-mgmt" $configFile | awk '{print $5}')
                BIP1=$(grep "${hostname}-bkp" $configFile | awk '{print $3"/"$4}')
                BGW1=$(grep "${hostname}-bkp" $configFile | awk '{print $5}')
                SCIP1=$(grep "${SVCName}-scan1" $configFile | awk '{print $3}')
                SCIP2=$(grep "${SVCName}-scan2" $configFile | awk '{print $3}')
                SCIP3=$(grep "${SVCName}-scan3" $configFile | awk '{print $3}')
                DNS1='172.17.58.97'
                DNS2='172.17.58.98'
        else
                echo "You could Copy/Paste the content of NISR/IP addresses sheet to the $configFile to Facilitate the process."
                hostname=''
                SVCName=''
                SIP1=''
                SGW1=''
                VIP1=''
                PIP11=''
                PGW11=''
                PIP12=''
                PGW12=''
                MIP1=''
                MGW1=''
                BIP1=''
                BGW1=''
                SCIP1=''
                SCIP2=''
                SCIP3=''
                DNS1='172.17.58.97'
                DNS2='172.17.58.98'
        fi
fi
echo "Type no (lowercase without extra character ) in front of every values you are NOT willing to be set..."
echo ""
read -rp "What is the ServiceName for this Oracle RAC Cluster (${SVCName}) : " choice; [[ -n "${choice}"  ]] &&  export SVCName="$choice";
read -rp "What is the Primary Service IP address/netmask of This node (${SIP1}) : " choice; [[ -n "${choice}"  ]] &&  export SIP1="$choice";
read -rp "What is the Primary GW of This node (${SGW1}) : " choice; [[ -n "${choice}"  ]] &&  export SGW1="$choice";
read -rp "What is the the assigned VIP address of this node (${VIP1}) : " choice; [[ -n "${choice}"  ]] &&  export VIP1="$choice";
read -rp "What is the First Scan IP (${SCIP1}) : " choice; [[ -n "${choice}"  ]] &&  export SCIP1="$choice";
read -rp "What is the Second Scan IP (${SCIP2}) : " choice; [[ -n "${choice}"  ]] &&  export SCIP2="$choice";
read -rp "What is the Third Scan IP (${SCIP3}) : " choice; [[ -n "${choice}"  ]] &&  export SCIP3="$choice";

read -rp "What is the the First Private IP/netmask address of this node (${PIP11}) : " choice; [[ -n "${choice}"  ]] &&  export PIP11="$choice";
read -rp "What is the the Second Private IP/netmask address of this node (${PIP12}) : " choice; [[ -n "${choice}"  ]] &&  export PIP12="$choice";

read -rp "What is the the Management IP/netmask address of this node (${MIP1}) : " choice; [[ -n "${choice}"  ]] &&  export MIP1="$choice";
read -rp "What is the the Backup IP/netmask address of this node (${BIP1}) : " choice; [[ -n "${choice}"  ]] &&  export BIP1="$choice";


searchif=true
while true
do
        read -p "We are going to search for the INTERFACES. It would take a while. Is it OK? [Y/N]" yn
        case $yn in
                [Yy] )
                        searchif=true
                        break
                        ;;
                [Nn] )
                        searchif=false
                        break
                        ;;
        esac
done
if [ $searchif == true ]
then
    SIF=()
        P1IF=()
        P2IF=()
        MIF=()
        BIF=()
        #we have a bug here in Ethernet filter
        for i in $(nmcli dev  | grep -v ^lo | grep 'ethernet' | awk '{print $1}' | tail -n +2)
        do
          arping -c 1 -D -q -I $i $SGW1
          if [ $? == 1 ]; then echo "$i $SGW1" ;SIF+=("$i"); fi

          arping -c 1 -D -q -I $i $PGW11
          if [ $? == 1 ]; then echo "$i $PGW11";P1IF+=("$i"); fi

          arping -c 1 -D -q -I $i $PGW12
          if [ $? == 1 ]; then echo "$i $PGW12" ;p2IF+=("$i"); fi

          arping -c 1 -D -q -I $i $BGW1
          if [ $? == 1 ]; then echo "$i $BGW1" ;BIF+=("$i"); fi

          arping -c 1 -D -q -I $i $MGW1
          if [ $? == 1 ]; then echo "$i $MGW1" ;MIF+=("$i"); fi

        done
fi
val=${SIF[@]}
read -rp "Which interfaces shall be use for Service Network ($val) : " choice; [[ -n "${choice}"  ]] &&  export SIF=($choice);
val=${P1IF[@]}
read -rp "Which interfaces shall be use for Private1 Network ($val) : " choice; [[ -n "${choice}"  ]] &&  export P1IF=($choice);
val=${P2IF[@]}
read -rp "Which interfaces shall be use for Private2 Network ($val) : " choice; [[ -n "${choice}"  ]] &&  export P2IF=($choice);
val=${MIF[@]}
read -rp "Which interfaces shall be use for Management Network ($val) : " choice; [[ -n "${choice}"  ]] &&  export MIF=($choice);
val=${BIF[@]}
read -rp "Which interfaces shall be use for Backup Network ($val) : " choice; [[ -n "${choice}"  ]] &&  export BIF=($choice);
echo "Saving your choices to the $file"
echo '' > $file
echo "export hostname=$hostname" >> $file
echo "export SVCName=$SVCName" >> $file
echo "export SIF=(${SIF[@]})" >> $file
echo "export P1IF=(${P1IF[@]})" >> $file
echo "export P2IF=(${P2IF[@]})" >> $file
echo "export MIF=(${MIF[@]})" >> $file
echo "export BIF=(${BIF[@]})" >> $file
echo "export SIP1=${SIP1}" >> $file
echo "export SGW1=${SGW1}" >> $file
echo "export VIP1=${VIP1}" >> $file
echo "export PIP11=${PIP11}" >> $file
echo "export PGW11=${PGW11}" >> $file
echo "export PIP12=${PIP12}" >> $file
echo "export PGW12=${PGW12}" >> $file
echo "export MIP1=${MIP1}" >> $file
echo "export MGW1=${MGW1}" >> $file
echo "export BIP1=${BIP1}" >> $file
echo "export BGW1=${BGW1}" >> $file
echo "export SCIP1=${SCIP1}" >> $file
echo "export SCIP2=${SCIP2}" >> $file
echo "export SCIP3=${SCIP3}" >> $file
echo "export DNS1=${DNS1}" >> $file
echo "export DNS2=${DNS2}" >> $file


echo -e "Type:\t\t\tIP Address\t\t\tGateway\t\tInterfaces";
if [ ${#SIF[@]} -gt 0 ] && [ ! -z ${SIP1} ] && [ ${SIP1} != 'no' ] && [ ${SIF[0]} != 'no' ]; then echo -e "Service:\t\t${SIP1} \t${SGW1} \t${SIF[@]}"; fi
if [ ${#P1IF[@]} -gt 0 ] && [ ! -z ${PIP11} ] && [ ${PIP11} != 'no' ] && [ ${P1IF[0]} != 'no' ]; then echo -e "Private1:\t\t${PIP11} \t${PGW11} \t${P1IF[@]}"; fi
if [ ${#P2IF[@]} -gt 0 ] && [ ! -z ${PIP12} ] && [ ${PIP12} != 'no' ] && [ ${P2IF[0]} != 'no' ]; then echo -e "Private2:\t\t${PIP12} \t${PGW11} \t${P2IF[@]}"; fi
if [ ${#MIF[@]} -gt 0 ] && [ ! -z ${MIP1} ] && [ ${MIP1} != 'no' ] && [ ${MIF[0]} != 'no' ]; then echo -e "Management:\t\t${MIP1} \t${MGW1} \t${MIF[@]}"; fi
if [ ${#BIF[@]} -gt 0 ] && [ ! -z ${BIP1} ] && [ ${BIP1} != 'no' ] && [ ${BIF[0]} != 'no' ]; then echo -e "Backup:    \t\t${BIP1} \t${BGW1} \t${BIF[@]}"; fi
echo ""
echo -e "SCAN IPs are: \t\t$SCIP1,$SCIP2,$SCIP3";
echo ""
echo "We are going to set the interface cards"
while true; do
    read -p "Will you continue (CHANGES ARE SAVED)? [Y/N]" yn
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

sed -i  '/kernel.printk=2 4 1 7/d' /etc/sysctl.conf
echo 'kernel.printk=2 4 1 7' >> /etc/sysctl.conf
sysctl -p > /dev/null

#Service Interface
if [ ${#SIF[@]} -gt 0 ] && [ ! -z ${SIP1} ] && [ ${SIP1} != 'no' ] && [ ${SIF[0]} != 'no' ]
then
    IP=$(echo ${SIP1} | awk -F/ '{print $1}')
    NM=$(NM2CIDR $(echo ${SIP1} | awk -F/ '{print $2}'))
        if [ ${#SIF[@]} -eq 1 ]
        then
                setSingleIF ${SIF[0]} $IP $NM $SGW1 $DNS1 $DNS2
        fi
        if [ ${#SIF[@]} -eq 2 ]
        then
                setTeamIF Team-Service ${SIF[0]} ${SIF[1]} $IP $NM $SGW1 $DNS1 $DNS2
        fi
        if [ ${#SIF[@]} -gt 2 ]
        then
                echo "incorrect number of interfaces for Service INTERFACES"
        fi
        sed -i  "/$IP/d" /etc/hosts
        echo "$IP ${hostname}" >> /etc/hosts
fi

if  [ ! -z ${VIP1} ]
then
        sed -i  "/$VIP1/d" /etc/hosts
        sed -i  "/${hostname}-vip/d" /etc/hosts
        echo "$VIP1 ${hostname}-vip" >> /etc/hosts
fi

if  [ ! -z ${SCIP1} ]
then
        sed -i  "/$SCIP1/d" /etc/hosts
        sed -i  "/${SVCName}-scan/d" /etc/hosts
        echo "$SCIP1 ${SVCName}-scan" >> /etc/hosts
        sed -i  "/$SCIP2/d" /etc/hosts
        echo "$SCIP2 ${SVCName}-scan" >> /etc/hosts
        sed -i  "/$SCIP3/d" /etc/hosts
        echo "$SCIP3 ${SVCName}-scan" >> /etc/hosts
fi


#Private1 Interface
if [ ${#P1IF[@]} -gt 0 ] && [ ! -z ${PIP11} ] && [ ${PIP11} != 'no' ] && [ ${P1IF[0]} != 'no' ]
then
    IP=$(echo ${PIP11} | awk -F/ '{print $1}')
    NM=$(NM2CIDR $(echo ${PIP11} | awk -F/ '{print $2}'))
        if [ ${#P1IF[@]} -eq 1 ]
        then
                setSingleIF ${P1IF[0]} $IP $NM
        fi
        if [ ${#P1IF[@]} -eq 2 ]
        then
                setTeamIF Team-Private1 ${P1IF[0]} ${P1IF[1]} $IP $NM
        fi
        if [ ${#P1IF[@]} -gt 2 ]
        then
                echo "incorrect number of interfaces for Private1 Service"
        fi
        sed -i  "/$IP/d" /etc/hosts
        sed -i  "/${hostname}-prv1/d" /etc/hosts
        echo "$IP ${hostname}-prv1" >> /etc/hosts
fi

#Priavte2 Interface
if [ ${#P2IF[@]} -gt 0 ] && [ ! -z ${PIP12} ] && [ ${PIP12} != 'no' ] && [ ${P2IF[0]} != 'no' ]
then
    IP=$(echo ${PIP12} | awk -F/ '{print $1}')
    NM=$(NM2CIDR $(echo ${PIP12} | awk -F/ '{print $2}'))
        if [ ${#P2IF[@]} -eq 1 ]
        then
                setSingleIF ${P2IF[0]} $IP $NM
        fi
        if [ ${#P2IF[@]} -eq 2 ]
        then
                setTeamIF Team-Private2 ${P2IF[0]} ${P2IF[1]} $IP $NM
        fi
        if [ ${#P2IF[@]} -gt 2 ]
        then
                echo "incorrect number of interfaces for Priavte2 Service"
        fi
        sed -i  "/$IP/d" /etc/hosts
        sed -i  "/${hostname}-prv2/d" /etc/hosts
        echo "$IP ${hostname}-prv2" >> /etc/hosts
fi

#Management Interface
if [ ${#MIF[@]} -gt 0 ] && [ ! -z ${MIP1} ] && [ ${MIP1} != 'no' ] && [ ${MIF[0]} != 'no' ]
then
    IP=$(echo ${MIP1} | awk -F/ '{print $1}')
    NM=$(NM2CIDR $(echo ${MIP1} | awk -F/ '{print $2}'))
        if [ ${#MIF[@]} -eq 1 ]
        then
                setSingleIF ${MIF[0]} $IP $NM
        fi
        if [ ${#MIF[@]} -eq 2 ]
        then
                setTeamIF Team-Management ${MIF[0]} ${MIF[1]} $IP $NM
        fi
        if [ ${#MIF[@]} -gt 2 ]
        then
                echo "incorrect number of interfaces for Management Service "
        fi
        sed -i  "/$IP/d" /etc/hosts
        sed -i  "/${hostname}-mgmt/t" /etc/hosts
        echo "$IP ${hostname}-mgmt" >> /etc/hosts
fi

#Backup Interface
if [ ${#BIF[@]} -gt 0 ] && [ ! -z ${BIP1} ] && [ ${BIP1} != 'no' ] && [ ${BIF[0]} != 'no' ]
then
    IP=$(echo ${BIP1} | awk -F/ '{print $1}')
    NM=$(NM2CIDR $(echo ${BIP1} | awk -F/ '{print $2}'))
        if [ ${#BIF[@]} -eq 1 ]
        then
                setSingleIF ${BIF[0]} $IP $NM
        fi
        if [ ${#BIF[@]} -eq 2 ]
        then
                setTeamIF Team-Backup ${BIF[0]} ${BIF[1]} $IP $NM
        fi
        if [ ${#BIF[@]} -gt 2 ]
        then
                echo "incorrect number of interfaces for Backup Service "
        fi
fi

#cluster config (ssh, other system) , test interfaces
