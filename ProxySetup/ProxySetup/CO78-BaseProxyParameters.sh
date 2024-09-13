#!/bin/bash
#This script get and set basic network information 
if [[ -f ~/proxysetup/variables.sh ]]
then
  source ~/proxysetup/variables.sh
fi


read -rp "IDM Hostname to use: ($IDMHOSTNAME): " choice; [[ -n "${choice}"  ]] &&  export IDMHOSTNAME="$choice"; 
read -rp "IDM IP to use: ($IDMIP): " choice; [[ -n "${choice}"  ]] &&  export IDMIP="$choice"; 
read -rp "IDM domain to use: ($IDMDomain): " choice; [[ -n "${choice}"  ]] &&  export IDMDomain="$choice";
read -rp "IDM Realm to use: ($IDMRealm): " choice; [[ -n "${choice}"  ]] &&  export IDMRealm="$choice";
read -rp "IDM Password to use: ($IDMPass): " choice; [[ -n "${choice}"  ]] &&  export IDMPass="$choice";

read -rp "Proxy Hostname to use: ($ProxyHOSTNAME): " choice;[[ -n "${choice}"  ]] &&  export ProxyHOSTNAME="$choice";
read -rp "Proxy IP to use: ($ProxyIP): " choice; [[ -n "${choice}"  ]] &&  export ProxyIP="$choice";
read -rp "Proxy Netmask to use (just the number of bits): ($ProxyNETMASK): " choice;	[[ -n "${choice}"  ]] &&  export ProxyNETMASK="$choice";
read -rp "Proxy GW to use: ($ProxyGW): " choice; [[ -n "${choice}"  ]] &&  export ProxyGW="$choice";

echo "export IDMHOSTNAME=$IDMHOSTNAME" > ~/proxysetup/variables.sh
echo "export IDMIP=$IDMIP" >> ~/proxysetup/variables.sh
echo "export IDMDomain=$IDMDomain" >> ~/proxysetup/variables.sh
echo "export IDMRealm=$IDMRealm" >> ~/proxysetup/variables.sh
echo "export IDMPass=$IDMPass" >> ~/proxysetup/variables.sh
echo "export ProxyHOSTNAME=$ProxyHOSTNAME" >> ~/proxysetup/variables.sh
echo "export ProxyIP=$ProxyIP" >> ~/proxysetup/variables.sh
echo "export ProxyNETMASK=$ProxyNETMASK" >> ~/proxysetup/variables.sh
echo "export ProxyGW=$ProxyGW" >> ~/proxysetup/variables.sh

ForemanIP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
echo "export ForemanIP=$ForemanIP" >> ~/proxysetup/variables.sh
ForemanHOSTNAME=$(hostname)
echo "export ForemanHOSTNAME=$ForemanHOSTNAME" >> ~/proxysetup/variables.sh
