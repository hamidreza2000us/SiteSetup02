#!/bin/bash
#Tested on Redhat 7.7
oraclepass=ahoora
gridpass=ahoora
ORACLE_VERSION=11.2.0.4

yum install -y oracle-database-preinstall-19c-1.0-3.el7.x86_64
#GridSoftwareName=11.2.0.4
#OracleSoftwareName=11.2.0.4

automated='false'
if [ $# -eq 1 ]
  then
  if [ $1 == 'automated' ]
    then
    automated='true'
  fi
fi

if [ $automated != 'true' ]; then
read -rp "What is the Oracle Version to Install: ($ORACLE_VERSION): " choice; [[ -n "${choice}"  ]] &&  export ORACLE_VERSION="$choice";
read -rp "Please set the default Password for Oracle User: ($oraclepass): " choice; [[ -n "${choice}"  ]] &&  export oraclepass="$choice";
read -rp "Please set the default Password for Grid User: ($gridpass): " choice; [[ -n "${choice}"  ]] &&  export gridpass="$choice";
fi

yum install -y bash-completion bc chrony lsof net-snmp net-snmp-utils net-tools nmap screen tcpdump telnet unzip vim sshpass

IntIP=$(ip a sh | grep "inet " | awk '{print $2}' | sed -n 2p | awk -F/ '{print $1}' )
sed -i "/$IntIP/d" /etc/hosts
echo "$IntIP $(hostname)" >> /etc/hosts
echo "$IntIP $(hostname -s)-vip.$(hostname -d) $(hostname -s)-vip" >> /etc/hosts

#CVUQDISK_GRP=oinstall; export CVUQDISK_GRP
#cat /sys/kernel/mm/transparent_hugepage/enabled

yumdownloader oracle-rdbms-server-11gR2-preinstall.x86_64 --destdir=/tmp/
rpm -ihv /tmp/oracle-rdbms-server-11gR2-preinstall-1.0-6.el7.x86_64.rpm --nodeps


yum install -y binutils compat-libcap1  compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libgcc libstdc++ libstdc++-devel libaio libaio-devel libXext libXtst libX11 libXau libxcb libXi make sysstat libXmu libXt libXv libXxf86dga libdmx libXxf86misc libXxf86vm xorg-x11-utils xorg-x11-xauth nfs-utils smartmontools elfutils-libelf-devel ksh mksh 
#yum -y install unixODBC unixODBC-devel 
yum -y install oracleasm oracleasm-support oracleasmlib 
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
echo "$oraclepass" | passwd --stdin grid
echo "$gridpass" | passwd --stdin oracle

sudo -u grid mkdir -p /home/grid/.ssh
sudo -u oracle mkdir -p /home/oracle/.ssh

sudo -u grid ssh-keygen -t rsa -N '' -f /home/grid/.ssh/id_rsa
sudo -u oracle ssh-keygen -t rsa -N '' -f /home/oracle/.ssh/id_rsa

sudo -u oracle sshpass -p ${oraclepass}  ssh-copy-id -i /home/oracle/.ssh/id_rsa.pub $(hostname)
sudo -u grid sshpass -p ${gridpass}  ssh-copy-id -i /home/grid/.ssh/id_rsa.pub $(hostname)
#call config_oracle_setting.sh

oracleasm configure -u oracle -g oinstall -s y -e

######################################all good#######################
cp /home/oracle/.bash_profile /home/oracle/.bash_profile.bkp
cat >> /home/oracle/.bash_profile << EOF
	export TMP=/tmp
	export TMPDIR=$TMP

	export ORACLE_HOSTNAME=$(hostname -f)
	#export ORACLE_UNQNAME=
	export ORACLE_BASE=/u01/app/oracle
	#export ORACLE_HOME=$ORACLE_BASE/product/12.1.0.2/db_1
	#export ORACLE_SID=

	export PATH=/usr/sbin:$PATH
	export PATH=$ORACLE_HOME/bin:$PATH
	export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
	export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
EOF

firewall-cmd --add-port={443,1521,5500}/tcp  --permanent
firewall-cmd --reload

#Experimental
#extra/scripts/configVNC.sh


#rpm -ihv ./rpms/cvuqdisk-1.0.10-1.rpm
#mkdir --parents /u01/app/$ORACLE_VERSION/grid
#chown --recursive grid:oinstall /u01

DownloadURL=satellite.idm.mci.ir
OracleSoftwarePath01=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_1of7.zip
OracleSoftwarePath02=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_2of7.zip
GridSoftwarePath=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_3of7.zip

wget http://${DownloadURL}/${GridSoftwarePath} -P /u01/app/$ORACLE_VERSION/
#chown grid:oinstall /u01/app/$ORACLE_VERSION/grid/*

mkdir --parents /u01/app/oracle
mkdir --parents /u01/app/oracle-software
chown --recursive oracle:oinstall /u01/app/oracle
chown --recursive oracle:oinstall /u01/app/oracle-software
mkdir /u01/app/oraInventory
chown --recursive oracle:oinstall /u01/app/oraInventory
wget http://${DownloadURL}/${OracleSoftwarePath01} -P /u01/app/oracle-software/
wget http://${DownloadURL}/${OracleSoftwarePath02} -P /u01/app/oracle-software/
#mv sources/$OracleSoftwareName /u01/app/oracle-software/
chown oracle:oinstall /u01/app/oracle-software/*

#cd /u01/app/$ORACLE_VERSION/grid
#sudo -u grid  unzip  *
#cd /u01/app/oracle-software
#sudo -u oracle unzip  *

#for file in $(ls /u01/app/$ORACLE_VERSION | grep zip) ; do sudo -u grid unzip /u01/app/$ORACLE_VERSION/$file -d /u01/app/$ORACLE_VERSION/ ; done
for file in $(ls /u01/app/$ORACLE_VERSION | grep zip) ; do sudo -u oracle unzip /u01/app/$ORACLE_VERSION/$file -d /u01/app/$ORACLE_VERSION/ ; done
for file in $(ls /u01/app/oracle-software/ | grep zip) ; do sudo -u oracle unzip  /u01/app/oracle-software/$file -d /u01/app/oracle-software/ ; done
rpm -ihv /u01/app/$ORACLE_VERSION/grid/rpm/cvuqdisk*

echo "Configure appropriate multipathing"
echo "Reboot the system"
echo "Configure disks for oracleasm before install grid"

#parted -s -a optimal /dev/sdb mklabel gpt mkpart primary  2048 100%
#oracleasm createdisk DATA_01 /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_deconfigure
#$ORACLE_HOME/bin/asmcmd afd_unlabel  /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_label DISK1 /dev/sdb1 --init
#$ORACLE_HOME/bin/asmcmd afd_lsdsk