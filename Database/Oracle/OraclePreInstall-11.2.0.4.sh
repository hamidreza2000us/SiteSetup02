#!/bin/bash
#Tested on Redhat 7.7
oraclepass="ahoora"
gridpass="ahoora"
ORACLE_VERSION=11.2.0.4
ORACLE_SID=testSID
NLS_LANG=AMERICAN_AMERICA.AL32UTF8

automated='false'
if [ $# -eq 1 ]
  then
  if [ $1 == 'automated' ]
    then
    automated='true'
  fi
fi

if [ $automated != 'true' ]; then
read -rp "Please set the default Password for Oracle User: ($oraclepass): " choice; [[ -n "${choice}"  ]] &&  export oraclepass="$choice";
read -rp "Please set the default Password for Grid User: ($gridpass): " choice; [[ -n "${choice}"  ]] &&  export gridpass="$choice";
read -rp "Please set the default SID for this Oracle DB: ($ORACLE_SID): " choice; [[ -n "${choice}"  ]] &&  export ORACLE_SID="$choice";
read -rp "Please set the NSL_LANG: ($NLS_LANG): " choice; [[ -n "${choice}"  ]] && export NLS_LANG="$choice";
fi

yum install -y bash-completion bc lsof net-snmp net-snmp-utils net-tools nmap screen tcpdump telnet unzip vim sshpass

IntIP=$(ip a sh | grep "inet " | awk '{print $2}' | sed -n 2p | awk -F/ '{print $1}' )
sed -i "/$IntIP/d" /etc/hosts
echo "$IntIP $(hostname)" >> /etc/hosts
echo "$IntIP $(hostname -s)-vip.$(hostname -d) $(hostname -s)-vip" >> /etc/hosts

#CVUQDISK_GRP=oinstall; export CVUQDISK_GRP
#cat /sys/kernel/mm/transparent_hugepage/enabled

yum install -y binutils compat-libcap1  compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libgcc libstdc++ libstdc++-devel libaio libaio-devel libXext libXtst libX11 libXau libxcb libXi make sysstat libXmu libXt libXv libXxf86dga libdmx libXxf86misc libXxf86vm xorg-x11-utils xorg-x11-xauth nfs-utils smartmontools elfutils-libelf-devel ksh mksh 
#yum -y install unixODBC unixODBC-devel 
yum -y install oracleasm oracleasm-support oracleasmlib 

#cp /etc/security/limits.conf /etc/security/limits.conf.bkp
#yumdownloader oracle-rdbms-server-11gR2-preinstall.x86_64 --destdir=/tmp/
#rpm -ihv /tmp/oracle-rdbms-server-11gR2-preinstall-1.0-6.el7.x86_64.rpm --nodeps
#rpm -e oracle-rdbms-server-11gR2-preinstall-1.0-6.el7.x86_64
#cp /etc/security/limits.conf.bkp /etc/security/limits.conf

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
echo "$oraclepass" | passwd --stdin oracle
echo "$gridpass" | passwd --stdin grid

sudo -u oracle mkdir -p /home/oracle/.ssh
sudo -u oracle ssh-keygen -t rsa -N '' -f /home/oracle/.ssh/id_rsa
sudo -u oracle sshpass -p ${oraclepass}  ssh-copy-id -i /home/oracle/.ssh/id_rsa.pub $(hostname)

sudo -u grid mkdir -p /home/grid/.ssh
sudo -u grid ssh-keygen -t rsa -N '' -f /home/grid/.ssh/id_rsa
sudo -u grid sshpass -p ${gridpass}  ssh-copy-id -i /home/grid/.ssh/id_rsa.pub $(hostname)


oracleasm configure -u grid -g oinstall -s y -e
oracleasm init

firewall-cmd --add-port={443,1521,5500}/tcp  --permanent
firewall-cmd --reload

#Experimental
#extra/scripts/configVNC.sh

wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/scripts/OraclePreInstall-Param-11.2.0.4.sh -P /tmp/
bash /tmp/OraclePreInstall-Param-11.2.0.4.sh
######################################all good#######################
cp /home/oracle/.bash_profile /home/oracle/.bash_profile.bkp

cat > /home/oracle/.bash_profile << 'EOF'
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
export TEMP=/tmp
export TMPDIR=/tmp

#export ORACLE_HOSTNAME=$(hostname -f)
#export ORACLE_UNQNAME=

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1
export ORACLE_SID=${ORACLE_SID}
JAVA_HOME=/usr/bin/java; export JAVA_HOME
export ORACLE_TERM=xterm
NLS_DATE_FORMAT="DD-MON-YYYY HH24:MI:SS"
export NLS_DATE_FORMAT
LD_LIBRARY_PATH=$ORACLE_HOME/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH
export SHLIB_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/rdbms/lib
# Set shell search paths:
# CLASSPATH must include the following JRE locations:
CLASSPATH=$ORACLE_HOME/JRE
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export CLASSPATH
export NLS_LANG=${NLS_LANG}
THREADS_FLAG=native; export THREADS_FLAG
PATH=${JAVA_HOME}/bin:${PATH}:$ORACLE_HOME/bin
PATH=${PATH}:/usr/bin:/bin:/usr/local/bin
export PATH

EOF

cat > /home/grid/.bash_profile << 'EOF'
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
export TEMP=/tmp
export TMPDIR=/tmp

#export ORACLE_HOSTNAME=$(hostname -f)
#export ORACLE_UNQNAME=

export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/11.2.0/grid/
export ORACLE_SID=${ORACLE_SID}
JAVA_HOME=/usr/bin/java; export JAVA_HOME
export ORACLE_TERM=xterm
NLS_DATE_FORMAT="DD-MON-YYYY HH24:MI:SS"
export NLS_DATE_FORMAT
LD_LIBRARY_PATH=$ORACLE_HOME/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH
export SHLIB_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/rdbms/lib
# Set shell search paths:
# CLASSPATH must include the following JRE locations:
CLASSPATH=$ORACLE_HOME/JRE
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export CLASSPATH
export NLS_LANG=${NLS_LANG}
THREADS_FLAG=native; export THREADS_FLAG
PATH=${JAVA_HOME}/bin:${PATH}:$ORACLE_HOME/bin
PATH=${PATH}:/usr/bin:/bin:/usr/local/bin
export PATH
EOF



DownloadURL=satellite.idm.mci.ir
OracleSoftwarePath01=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_1of7.zip
OracleSoftwarePath02=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_2of7.zip
GridSoftwarePath=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_3of7.zip

mkdir --parents /u01/app/software
mkdir --parents /u01/app/oracle
mkdir --parents /u01/app/$ORACLE_VERSION
mkdir --parents /u01/app/11.2.0
#mkdir /u01/app/oraInventory
wget http://${DownloadURL}/${GridSoftwarePath} -P /u01/app/software/
wget http://${DownloadURL}/${OracleSoftwarePath01} -P /u01/app/software/
wget http://${DownloadURL}/${OracleSoftwarePath02} -P /u01/app/software/
chown --recursive oracle:oinstall /u01
chmod 775 /u01/app
chmod 775 /u01/app/11.2.0
#chmod 775 /u01/app/oraInventory

for file in $(ls /u01/app/software | grep zip) ; do sudo -u oracle unzip /u01/app/software/$file -d /u01/app/$ORACLE_VERSION/ ; done
rpm -ihv /u01/app/$ORACLE_VERSION/grid/rpm/cvuqdisk*


echo "grid ALL=(root) NOPASSWD:/u01/app/oraInventory/orainstRoot.sh,/u01/app/11.2.0/grid/root.sh" >> /etc/sudoers
echo "oracle ALL=(root) NOPASSWD:/u01/app/oracle/product/11.2.0/db_1/root.sh" >> /etc/sudoers

###################################################################################
#wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/scripts/db.rsp -P /home/oracle/
#wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/scripts/grid.rsp -P /home/grid/
#sed -i "s/HHHOST___NAMEEE/$(hostname -f)/g" /home/oracle/db.rsp
#sed -i "s/HHHOST___NAMEEE/$(hostname -f)/g" /home/grid/grid.rsp
#sudo -u grid /u01/app/11.2.0.4/grid/runInstaller -ignoreSysPrereqs  -waitforcompletion -ignorePrereq -silent -showProgress -responseFile /home/grid/grid.rsp
#/u01/app/11.2.0/grid/root.sh
#sudo -u oracle /u01/app/11.2.0.4/database/runInstaller -ignoreSysPrereqs -waitforcompletion -ignorePrereq -silent -showProgress -responseFile /home/oracle/db.rsp
#/u01/app/oracle/product/11.2.0/db_1/root.sh
###################################################################################

echo "Configure appropriate multipathing"
echo "Reboot the system"
echo "Configure disks for oracleasm before install grid"
#/u01/app/11.2.0.4/database/runInstaller -executePrereqs

#parted -s -a optimal /dev/sdb mklabel gpt mkpart primary  2048 100%
#oracleasm createdisk DATA_01 /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_deconfigure
#$ORACLE_HOME/bin/asmcmd afd_unlabel  /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_label DISK1 /dev/sdb1 --init
#$ORACLE_HOME/bin/asmcmd afd_lsdsk

#grid user
#cluster configs 
#vnc config 
#disk partition 

