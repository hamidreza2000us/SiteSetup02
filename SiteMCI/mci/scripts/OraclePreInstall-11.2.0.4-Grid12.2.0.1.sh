#!/bin/bash
#Tested on Redhat 7.7
oraclepass="ahoora"
gridpass="ahoora"
ORACLE_VERSION=11.2.0.4
GRID_VERSION=12.2.0.1
ORACLE_SID=testSID
GRID_SID='+ASM1'
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
read -rp "Please set the default SID for this Oracle DB: ($GRID_SID): " choice; [[ -n "${choice}"  ]] &&  export GRID_SID="$choice";
read -rp "Please set the NSL_LANG: ($NLS_LANG): " choice; [[ -n "${choice}"  ]] && export NLS_LANG="$choice";
fi

yum install -y bash-completion bc lsof net-snmp net-snmp-utils net-tools nmap screen tcpdump telnet unzip vim sshpass

#IntIP=$(ip a sh | grep "inet " | awk '{print $2}' | sed -n 2p | awk -F/ '{print $1}' )
#sed -i "/$IntIP/d" /etc/hosts
#echo "$IntIP $(hostname)" >> /etc/hosts
#echo "$IntIP $(hostname -s)-vip.$(hostname -d) $(hostname -s)-vip" >> /etc/hosts

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


oracleasm configure -u grid -g asmadmin -s y -e
oracleasm init
oracleasm scandisks

firewall-cmd --add-port={443,1521,5500}/tcp  --permanent
firewall-cmd --reload

#Experimental
#extra/scripts/configVNC.sh

rm -rf /tmp/OraclePreInstall-Param-11.2.0.4.sh*
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

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1
export ORACLE_SID=ORACLE_SID_TEMP
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

sed  -i "s/ORACLE_SID_TEMP/${ORACLE_SID}/g" /home/oracle/.bash_profile
chown oracle:oinstall /home/oracle/.bash_profile

cat > /home/grid/.bash_profile << 'EOF'
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
export TEMP=/tmp
export TMPDIR=/tmp

export ORACLE_BASE=/u01/base/grid
export ORACLE_HOME=/u01/app/grid/product/12.2.0/grid
export ORACLE_SID=GRID_SID_TEMP
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

sed  -i "s/GRID_SID_TEMP/${GRID_SID}/g" /home/grid/.bash_profile
chown grid:oinstall /home/grid/.bash_profile


DownloadURL=satellite.idm.mci.ir
OracleSoftwarePath01=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_1of7.zip
OracleSoftwarePath02=pub/RHEL/Oracle/DB/Linux/11.2.0.4/p13390677_112040_Linux-x86-64_2of7.zip
GridSoftwarePath=pub/RHEL/Oracle/DB/Linux/12.2.0.1/linuxx64_12201_grid_home.zip

GridOpatch01=pub/RHEL/Oracle/DB/Linux/Patch/grid/p6880880_122010_Linux-x86-64.zip
GridOpatch02=pub/RHEL/Oracle/DB/Linux/Patch/grid/p26247490_12201180417ACFSApr2018RU_Linux-x86-64.zip
OracleOpatch01=pub/RHEL/Oracle/DB/Linux/Patch/db/p19404309_112040_Linux-x86-64.zip

mkdir --parents /u01/software
mkdir -p /u01/software/patch/{grid,db}
mkdir --parents /u01/app/grid/product/12.2.0/grid
mkdir --parents /u01/base/grid

wget http://${DownloadURL}/${GridSoftwarePath} -P /u01/software/
wget http://${DownloadURL}/${OracleSoftwarePath01} -P /u01/software/
wget http://${DownloadURL}/${OracleSoftwarePath02} -P /u01/software/

wget http://${DownloadURL}/${GridOpatch01} -P /u01/software/patch/grid/
wget http://${DownloadURL}/${GridOpatch02} -P /u01/software/patch/grid/
wget http://${DownloadURL}/${OracleOpatch01} -P /u01/software/patch/db

chown --recursive oracle:oinstall /u01
chown --recursive grid:oinstall /u01/app/grid
chown --recursive grid:oinstall /u01/base/grid
chown --recursive grid:oinstall /u01/software/patch/grid

sudo -u grid unzip /u01/software/linuxx64_12201_grid_home.zip -d /u01/app/grid/product/12.2.0/grid
chown grid:oinstall /u01/app/
sudo -u oracle unzip /u01/software/p13390677_112040_Linux-x86-64_1of7.zip -d /u01/software
sudo -u oracle unzip /u01/software/p13390677_112040_Linux-x86-64_2of7.zip -d /u01/software

sudo -u grid unzip -o /u01/software/patch/grid/p6880880_122010_Linux-x86-64.zip -d /u01/app/grid/product/12.2.0/grid
sudo -u grid unzip -o /u01/software/patch/grid/p26247490_12201180417ACFSApr2018RU_Linux-x86-64.zip -d /u01/software/patch/grid
sudo -u oracle unzip /u01/software/patch/db/p19404309_112040_Linux-x86-64.zip -d /u01/software/patch/db
sudo -u oracle \cp -f /u01/software/patch/db/b19404309/database/cvu_prereq.xml /u01/software/database/stage/cvu/

#/u01/app/grid/product/12.2.0/grid/OPatch/opatchauto apply /u01/software/patch/grid/26247490 -oh /u01/app/grid/product/12.2.0/grid -norestart

mkdir --parents /u01/app/oracle
chown --recursive oracle:oinstall  /u01/app/oracle

rpm -ihv /u01/app/grid/product/12.2.0/grid/cv/rpm/cvuqdisk*

sed -i  '/grid ALL=(root) NOPASSWD:/d' /etc/sudoers
echo "grid ALL=(root) NOPASSWD:/u01/app/oraInventory/orainstRoot.sh,/u01/app/grid/product/12.2.0/grid/root.sh,/u01/app/grid/product/12.2.0/grid/OPatch/opatchauto" >> /etc/sudoers
#echo "grid ALL=(root) NOPASSWD:/u01/app/12.2.0/grid/root.sh" >> /etc/sudoers
sed -i  '/oracle ALL=(root) NOPASSWD:/d' /etc/sudoers
echo "oracle ALL=(root) NOPASSWD:/u01/app/oracle/product/11.2.0/db_1/root.sh,/u01/app/grid/product/12.2.0/grid/OPatch/opatchauto" >> /etc/sudoers

###################################################################################
#wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/scripts/db.rsp -P /home/oracle/
#wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/scripts/grid.rsp -P /home/grid/
#sed -i "s/HHHOST___NAMEEE/$(hostname -f)/g" /home/oracle/db.rsp
#sed -i "s/HHHOST___NAMEEE/$(hostname -f)/g" /home/grid/grid.rsp
#sudo -u grid /u01/app/12.2.0/grid/gridSetup.sh -ignoreSysPrereqs  -waitforcompletion -ignorePrereq -silent -showProgress -responseFile /home/grid/grid.rsp
#/u01/app/12.2.0/grid/root.sh
#sudo -u oracle /u01/app/11.2.0/oracle/database/runInstaller -ignoreSysPrereqs -waitforcompletion -ignorePrereq -silent -showProgress -responseFile /home/oracle/db.rsp
#/u01/app/oracle/product/11.2.0/db_1/root.sh
###################################################################################

echo "1- Run: https://satellite.idm.mci.ir/pub/RHEL/Linux/scripts/ConfigOracleRACInterface.sh For Interfaces (dont forget /tmp/NISR)"
echo "2- Run: https://satellite.idm.mci.ir/pub/RHEL/Linux/scripts/ConfigPasslessSSH.sh For Passless authentication"
echo "3- Run: https://satellite.idm.mci.ir/pub/RHEL/Linux/scripts/InstallUltraPath.sh for Ultrapath setup"
echo "4- Run: https://satellite.idm.mci.ir/pub/RHEL/Linux/scripts/InstallIB.sh for Infiniband setup"
echo "5- Reboot the system"
echo "6- On second node you may remove /u01/app/grid and /u01/software/database"
echo "7- Label disks with oracleasm before install grid"
#/u01/app/11.2.0/oracle/database/runInstaller -executePrereqs
#/u01/app/12.2.0/grid/gridSetup.sh -executePrereqs

#parted -s -a optimal /dev/sdb mklabel gpt mkpart primary  2048 100%
#oracleasm createdisk DATA_01 /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_deconfigure
#$ORACLE_HOME/bin/asmcmd afd_unlabel  /dev/sdb1
#$ORACLE_HOME/bin/asmcmd afd_label DISK1 /dev/sdb1 --init
#$ORACLE_HOME/bin/asmcmd afd_lsdsk

if [ -f /etc/ntp.conf ] ; then mv /etc/ntp.conf /etc/ntp.conf.bkp ; fi

#vnc config
#disk partition


