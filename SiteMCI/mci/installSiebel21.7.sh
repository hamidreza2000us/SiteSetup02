oraPass=ahoora

yum -y install wget ksh tcsh  ksh tcsh  strace hostname iproute nc lsof dos2unix vi iputils  libxcb.i686  libX11.i686  libXext.i686  libXau.i686  glibc.i686  libaio.i686  libstdc++.i686 
yum -y update libstdc++.x86_64
#etc/hosts
groupadd -g  1000 siebel && useradd -m -g siebel -G siebel -u 1000 siebel -d /u01
# cp -p /etc/skel/.bash* /u01/ && chown -R siebel /u01/
echo -n ${oraPass} | passwd --stdin siebel

#gencert.sh
#OracleClientIstall-12.2.sh

######################################
mem=$(free -b | awk '/Mem/ {print $2}')
page=$(getconf PAGE_SIZE)
all=$(expr $mem \* 75 / 100 / $page + 1)
max=$(expr $all \* $page)

cat > /etc/sysctl.d/90-siebel.conf << EOF
kernel.shmmax = $max
kernel.shmall = $all
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
fs.file-max = 6815744
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF

#no proc and nofile seems low/double check
cat >> /etc/security/limits.conf << EOF
siebel   soft   nofile    1024
siebel   hard   nofile    65536
siebel   soft   nproc    16384
siebel   hard   nproc    16384
siebel   soft   stack    10240
siebel   hard   stack    32768
EOF

#reboot to take effect
#set tnsnames and check tnsping

###################################################
mkdir /u01/stage
cd /u01/stage
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_2of6.zip -P /u01/stage
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_3of6.zip -P /u01/stage
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_4of6.zip -P /u01/stage
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_6of6.zip -P /u01/stage


###################################################
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/db_func_proc.sql -P /u01/stage
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/set_unicode.sql -P /u01/stage
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/sqlnet.ora -P /u01/stage
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/store_history.sql  -P /u01/stage

##########################################
wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/scripts/OracleClientInstall-12.2.sh -P /tmp
bash /tmp/OracleClientInstall-12.2.sh

###########################################
chown -R siebel:siebel /u01/stage
#####################bash profile for siebel profile is missing#####################

su - siebel 
time for i in `ls /u01/stage/p*.zip`; do unzip $i -d /u01/stage/; done

####################################

mkdir /u01/fs
# mkdir -p /u01/app/oraInventory 
echo inventory_loc=/u01/app/oraInventory > /u01/app/oraInventory/oraInst.loc
echo inst_group=siebel >> /u01/app/oraInventory/oraInst.loc

cd /u01/stage/Disk1/install
./runInstaller.sh -invPtrLoc /u01/app/oraInventory/oraInst.loc
#./runInstaller -invPtrLoc /u01/app/oraInventory/oraInst.loc -silent -responseFile /u01/stai.rsp
#su siebel -c "bash /mnt/Siebel_Enterprise_Server/Disk1/install/runInstaller.sh -silent -responseFile /config/mde.rsp -invPtrLoc /config/oraInst.loc -waitforcompletion -showProgress > /config/SiebelInstall.log 2>&1"

#ENV ORACLE_HOME=/usr/lib/oracle/12.2/client \
#    TNS_ADMIN=/config/ \
#    LD_LIBRARY_PATH="/usr/lib/oracle/12.2/client/lib:${LD_LIBRARY_PATH}"  \
#    PATH="/usr/lib/oracle/12.2/client/bin:${PATH}" \
#    LANG=en_US.UTF-8 \
#    RESOLV_MULTI=off

firewall-cmd --add-port=8005/tcp --add-port=8006/tcp --add-port=8080/tcp --add-port=8081/tcp --add-port=8443/tcp --add-port=8444/tcp  --permanent
success
firewall-cmd --reload
#config selinux

#create tablespace SIEBEL_DATA
#use following variable when running the script below
#un_tableowner: siebel
#pw_tableowner: oracle
#default_tablespace: SIEBEL_DATA
#temporary_tablespace: TEMP
#pw_sadmin: oracle
#pw_ldapuser: oracle
#pw_gcstuser: oracle
#pw_gstermuser: oracle

#/u01/ses/dbsrvr/oracle/grantusr.sql
#bash  /u01/ses/config/config.sh -mode dbsrvr
# /u01/ses/siebsrvr/bin/odbcsql /u sadmin /p oracle



