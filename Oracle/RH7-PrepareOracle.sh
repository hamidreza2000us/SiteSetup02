#!/bin/bash
#Tested on Redhat 7.7
source variable.sh
mkdir /mnt/cdrom
mount /dev/cdrom /mnt/cdrom/
if [ $(ls /mnt/cdrom/ | wc -l) == 0 ]
then
  echo "The CD is not mounted";
  exit
fi
cp files/cd.repo /etc/yum.repos.d/cd.repo
mount /dev/cdrom /mnt/cdrom
yum update
if [ $? != 0 ]
then
  echo "The packaging system is not configured properly";
  exit
fi
yum install -y bash-completion bc tuned chrony lsof net-snmp net-snmp-utils net-tools nmap screen tcpdump telnet unzip vim
systemctl enable tuned.service
systemctl start tuned.service
yum localinstall -y rpms/crudini*

IntIP=$(ip a sh | grep "inet " | awk '{print $2}' | sed -n 2p | awk -F/ '{print $1}' )
sed -i "/$IntIP/d" /etc/hosts
echo "$IntIP $hostname" >> /etc/hosts
hostnamectl set-hostname $hostname
timedatectl set-timezone $timezone
sed -i '/^server/d' /etc/chrony.conf
sed -i "3iserver $ntp1 iburst" /etc/chrony.conf
systemctl restart chronyd
systemctl enable chronyd
crudini --set /etc/sysconfig/selinux '' SELINUX disabled

#Experimental functions
#extra/scripts/configAnsible.sh
#extra/scripts/configNet.sh
#########################oracle preinstall######################

yum install -y binutils compat-libcap1 compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libgcc libstdc++ libstdc++-devel libaio libaio-devel libXext libXtst libX11 libXau libxcb libXi make sysstat libXmu libXt libXv libXxf86dga libdmx libXxf86misc libXxf86vm xorg-x11-utils xorg-x11-xauth nfs-utils smartmontools
yum list kmod-oracleasm > /dev/null 2>&1
[[ $? == 0 ]] && yum install -y kmod-oracleasm || yum localinstall -y rpms/kmod-oracleasm* ;
[[ $? == 0 ]]  || echo $("kmod-oracleasm for this kernel is not available\nFailed....";exit)
yum localinstall -y rpms/oracleasm*

mkdir /usr/lib/tuned/oracle/
cp files/tuned.conf /usr/lib/tuned/oracle/tuned.conf
tuned-adm profile oracle

cp files/98-oracle-sysctl.conf /etc/sysctl.d/
cp files/99-oracle-limits.conf /etc/security/limits.d/

groupadd --gid 54321 oinstall
groupadd --gid 54322 dba
groupadd --gid 54323 asmdba
groupadd --gid 54324 asmoper
groupadd --gid 54325 asmadmin
groupadd --gid 54326 oper
groupadd --gid 54327 backupdba
groupadd --gid 54328 dgdba
groupadd --gid 54329 kmdba
groupadd --gid 54330 racdba
useradd -m --uid 54321 --gid oinstall --groups dba,oper,asmdba,racdba,backupdba,dgdba,kmdba oracle
useradd -m --uid 54322 --gid oinstall --groups dba,asmadmin,asmdba,asmoper,racdba grid
echo $oraclepass | passwd --stdin grid
echo $gridpass | passwd --stdin oracle

oracleasm configure -u oracle -g oinstall -s y -e

cat files/db_bash_profile > /home/oracle/.bash_profile
crudini --set /home/oracle/.bash_profile '' ORACLE_SID $ORACLE_SID
crudini --set /home/oracle/.bash_profile '' ORACLE_UNQNAME $ORACLE_UNQNAME
crudini --set /home/oracle/.bash_profile '' ORACLE_HOME '$ORACLE_BASE/product/'$ORACLE_VERSION'/db_1;'
cat files/grid_bash_profile > /home/grid/.bash_profile
crudini --set /home/grid/.bash_profile '' ORACLE_SID $GRID_SID
crudini --set /home/grid/.bash_profile '' ORACLE_HOME '$ORACLE_BASE/'$GRID_VERSION'/grid'

firewall-cmd --add-port={443,1521,5500}/tcp  --permanent
firewall-cmd --reload

#Experimental
#extra/scripts/configVNC.sh

rpm -ihv ./rpms/cvuqdisk-1.0.10-1.rpm
mkdir --parents /u01/app/$ORACLE_VERSION/grid
chown --recursive grid:oinstall /u01
mv sources/$GridSoftwareName /u01/app/$ORACLE_VERSION/grid
chown grid:oinstall /u01/app/$ORACLE_VERSION/grid/$GridSoftwareName
mkdir --parents /u01/app/oracle
mkdir --parents /u01/app/oracle-software
chown --recursive oracle:oinstall /u01/app/oracle
chown --recursive oracle:oinstall /u01/app/oracle-software
mkdir /u01/app/oraInventory
chown --recursive oracle:oinstall /u01/app/oraInventory
mv sources/$OracleSoftwareName /u01/app/oracle-software/
chown oracle:oinstall /u01/app/oracle-software/$OracleSoftwareName
cd /u01/app/$ORACLE_VERSION/grid
sudo -u grid  unzip  $GridSoftwareName
cd /u01/app/oracle-software
sudo -u oracle unzip  $OracleSoftwareName
#rpm -ihv /u01/app/$ORACLE_VERSION/grid/cv/rpm/cvuqdisk*

echo "Configure appropriate multipathing"
echo "Reboot the system"
echo "Configure disks for oracleasm before install grid"

#parted -s -a optimal /dev/sdb mklabel gpt mkpart primary  2048 100%
#oracleasm createdisk DATA_01 /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_deconfigure
#$ORACLE_HOME/bin/asmcmd afd_unlabel  /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_label DISK1 /dev/sdb1 --init
#$ORACLE_HOME/bin/asmcmd afd_lsdsk


 