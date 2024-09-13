sblRoot=/u01/app
sblHome=/u01/app/siebel


declare -A sourcesPath
sourcesPath[0]=http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_2of6.zip
sourcesPath[1]=http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_3of6.zip
sourcesPath[2]=http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_4of6.zip
sourcesPath[3]=http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_6of6.zip

export automated='false'
if [ $# -eq 1 ]
  then
  if [ $1 == 'automated' ]
    then
	if [ -f /tmp/values ]
	then 
	  source /tmp/values ; 
      export automated='true';
	fi
  fi
fi

echo -e "This script setup siebel software."
echo -e "Prior to this step the oracle database with APPROPRIATE version should be ready with firewall configured"
echo -e "and tns information are available"

if [ $automated != 'true' ]; then
  oraUser=siebel
  oraPass=ahoora
  instMethod=1
  echo -e " 1) GW or SS \n 2) Application Interface \n 3) ALL In One"
  read -rp "Which type of Installation this server would have ($instMethod): " choice; [[ -n "${choice}"  ]] &&  export instMethod="$choice";
  read -rp "What is the username to use for siebel application: ($oraUser) " choice; [[ -n "${choice}"  ]] &&  export oraUser="$choice";
  read -rp "What is the password to use for siebel application: ($oraPass) " choice; [[ -n "${choice}"  ]] &&  export oraPass="$choice";
  echo '' > /tmp/values
  export instMethod="${instMethod}" 
  export oraUser="${oraUser}" 
  export oraPass="${oraPass}" 
  export siebelUserInherit=true;
  echo "export instMethod=\"${instMethod}\"" >> /tmp/values
  echo "export oraUser=\"${oraUser}\"" >> /tmp/values
  echo "export oraPass=\"${oraPass}\"" >> /tmp/values
  echo "export sblRoot=\"${sblRoot}\"" >> /tmp/values
  echo "export sblHome=\"${sblHome}\"" >> /tmp/values
fi  
#java-1.8.0-openjdk-devel
#java -jar /u01/app/software/Disk1/stage/ext/jlib/EncryptString.jar "ahoora"
#yum -y install wget ksh tcsh  ksh tcsh  strace hostname iproute nc lsof dos2unix vi iputils  libxcb.i686  libX11.i686  libXext.i686  libXau.i686  glibc.i686  libaio.i686  libstdc++.i686 
yum -y install wget ksh tcsh  ksh tcsh  strace hostname iproute nc lsof dos2unix vi iputils  libxcb.i686  libX11  libXext.i686  libXau.i686  glibc.i686  libaio.i686  libstdc++.i686 
yum -y update libstdc++.x86_64
#etc/hosts
if ! id ${oraUser} &>/dev/null;
then     
   groupadd oinstall ;
   useradd -m -g oinstall -G oinstall ${oraUser} 
   echo -n ${oraPass} | passwd --stdin ${oraUser}
   chmod 600 /tmp/values
   chown ${oraUser} /tmp/values
fi
#cp -p /etc/skel/.bash* /u01/ && chown -R siebel /u01/

wget http://satellite.idm.mci.ir/pub/RHEL/Linux/scripts/GenerateSSLCertificates.sh -P /tmp/
time bash /tmp/GenerateSSLCertificates.sh
wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/scripts/OracleClientInstall-12.2.sh -P /tmp/
time bash /tmp/OracleClientInstall-12.2.sh

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
#####################bash profile for siebel profile is missing#####################

firewall-cmd --add-port=8005/tcp --add-port=8006/tcp --add-port=8080/tcp --add-port=8081/tcp --add-port=8443/tcp --add-port=8444/tcp  --permanent
firewall-cmd --add-port=2320/tcp --add-port=2321/tcp --add-port=2322/tcp --add-port=2323/tcp --add-port=2324/tcp --add-port=2330/tcp  --permanent
firewall-cmd --reload
#config selinux

userhomedir=$(eval echo ~${oraUser})
 echo "export userhomedir=\"${userhomedir}\"" >> /tmp/values
sudo -u ${oraUser} cat >> ${userhomedir}/.bash_profile << 'EOF'
export SIEBEL_HOME=sblHome; 
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SIEBEL_HOME/siebsrvr/lib
EOF

sed  "s|sblHome|${sblHome}|g" -i ${userhomedir}/.bash_profile


###################################################
sudo -u ${oraUser} mkdir -p ${sblRoot}/software
cd ${sblRoot}/software

echo "downloading the installation files, it would take few minutes..."
time for i in $(seq 0 $[${#sourcesPath[@]}-1] ) ; do sudo -u ${oraUser} wget "${sourcesPath[$i]}" -P ${sblRoot}/software  & done
wait

cd ${sblRoot}/software/
echo "extracting the installation files, it would take few minutes..."
time for i in $(seq 0 $[${#sourcesPath[@]}-1] ) ; do sudo -u ${oraUser} unzip ${sblRoot}/software/$(basename ${sourcesPath[$i]} )   &   done
wait

####################################
##?????
sudo -u ${oraUser} mkdir /u01/fs
# mkdir -p /u01/app/oraInventory 
#echo inventory_loc=/u01/app/oraInventory > /u01/app/oraInventory/oraInst.loc
#echo inst_group=siebel >> /u01/app/oraInventory/oraInst.loc
. /tmp/values.exported
UserPassHash=$(java -jar ${sblRoot}/software/Disk1/stage/ext/jlib/EncryptString.jar ${oraPass})
KeyStoreHash=$(java -jar ${sblRoot}/software/Disk1/stage/ext/jlib/EncryptString.jar ${keystorepass})

case $instMethod in
	1)
	   INec=true;INdbrepo=true;INanrepo=true;INecc=true;INacc=false;
	  ;;
	2)
	   INec=true;INdbrepo=false;INanrepo=false;INecc=false;INacc=true;
	  ;;
	*) 
	   INec=true;INdbrepo=true;INanrepo=true;INecc=true;INacc=true;
	  ;;
esac
cat > ${userhomedir}/silent.rsp << EOF
[Siebel_Installation_Details]
INSTALL_TYPE="New Installation"
ORACLE_HOME="${sblHome}"
SELECTED_LANGUAGES="en,ar"
[Siebel_Installation_Components]
ENTERPRISE_CONTAINER_CONFIGURATION="${INecc}"
AI_CONTAINER_CONFIGURATION="${INacc}"
SIEBEL_WEB_CLIENT_CONFIGURATION="false"
SIEBEL_WEB_TOOLS_CONFIGURATION="false"
SIEBEL_ENTERPRISE_COMPONENT="${INec}"
SIEBEL_APPLICATION_INTERFACE="TRUE"
DB_REPOSITORY_SUPPORT="${INdbrepo}"
ANCESTOR_REPO_SUPPORT="${INanrepo}"
SIEBEL_WEB_CLIENT="FALSE"
SIEBEL_WEB_TOOLS="FALSE"
HTTP_PORT_EC="8081"
SHUTDOWN_PORT_EC="8006"
REDIRECT_PORT_EC="8444"
HTTP_PORT_AI="8080"
SHUTDOWN_PORT_AI="8005"
REDIRECT_PORT_AI="8443"
USERNAME="sadmin"
PASSWORD="${UserPassHash}"
KEYSTORE_NAME_EC="${keystoredir}/keystore.jks"
KEYSTORE_PASSWORD_EC="${KeyStoreHash}"
KEYSTORE_TYPE_EC="JKS"
TRUSTSTORE_NAME_EC="${keystoredir}/truststore.jks"
TRUSTSTORE_PASSWORD_EC="${KeyStoreHash}"
TRUSTSTORE_TYPE_EC="JKS"
KEYSTORE_NAME_AI="${keystoredir}/keystore.jks"
KEYSTORE_PASSWORD_AI="${KeyStoreHash}"
KEYSTORE_TYPE_AI="JKS"
TRUSTSTORE_NAME_AI="${keystoredir}/truststore.jks"
TRUSTSTORE_PASSWORD_AI="${KeyStoreHash}"
TRUSTSTORE_TYPE_AI="JKS"
DEPLOYMENT_TYPE="standard"
DEPLOYMENT_LOCATION=""
EOF


#generate silent file!!!!!
cd ${sblRoot}/software/Disk1/install
#sudo -u ${oraUser} ./runInstaller.sh -invPtrLoc ${sblRoot}/oraInventory/oraInst.loc
#sudo -u ${oraUser} ./runInstaller -invPtrLoc /u01/app/oraInventory/oraInst.loc -silent -waitforcompletion -showProgress -responseFile /u01/stai.rsp
time su ${oraUser} -c "cd ~; source ${userhomedir}/.bash_profile ; bash ${sblRoot}/software/Disk1/install/runInstaller.sh -silent -responseFile ${userhomedir}/silent.rsp -invPtrLoc /u01/app/oraInventory/oraInst.loc -waitforcompletion -showProgress"
#echo "time su ${oraUser} -c source ${userhomedir}/.bash_profile ; bash ${sblRoot}/software/Disk1/install/runInstaller.sh -silent -responseFile ${userhomedir}/silent.rsp -invPtrLoc /u01/app/oraInventory/oraInst.loc -waitforcompletion -showProgress"
#you need to install application interface to use web gui access for further configuration
###################################################????
sudo -u ${oraUser} mkdir -p ${sblHome}/dbsrvr/oracle/
sudo -u ${oraUser} wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/db_func_proc.sql -P ${sblHome}/dbsrvr/oracle/
sudo -u ${oraUser} wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/set_unicode.sql -P ${sblHome}/dbsrvr/oracle/
sudo -u ${oraUser} wget http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/store_history.sql  -P ${sblHome}/dbsrvr/oracle/
###########################################

#In case of error in grantusr script run below commands:
#drop user siebel cascade;
#drop role sse_role ;
#drop role tblo_role ;
#drop user sadmin cascade;
#drop user ldapuser cascade;
#drop user guestcst cascade;
#drop user guesterm cascade;

#this part not tested
echo "switch to siebel user:"
echo "sadmin password is temporarily set to siebel user password"
echo "If you have access to the database with a privilege user run the following commands:"
echo "grant sysdba,dba,connect,resource  to tempuser identified by temppass;"
echo "sqlplus tempuser/temppass@orcl "
echo "create tablespace SIEBEL_DATA DATAFILE 'test.dbf' size 1G autoextend on;"
echo "create tablespace SIEBEL_INDEX DATAFILE 'test2.dbf' size 1G autoextend on;"
echo "@${sblHome}/dbsrvr/oracle/grantusr.sql"
echo "alter user siebel quota unlimited on siebel_index;"
echo "GRANT UNLIMITED TABLESPACE TO siebel;"
echo "Otherwise ask DBA to run this script: ${sblHome}/dbsrvr/oracle/grantusr.sql with following values:"
echo "#un_tableowner: siebel"
echo "#pw_tableowner: ${oraPass}"
echo "#default_tablespace: SIEBEL_DATA"
echo "#temporary_tablespace: TEMP"
echo "#pw_sadmin: ${oraPass}"
echo "#pw_ldapuser: ${oraPass}"
echo "#pw_gcstuser: ${oraPass}"
echo "#pw_gstermuser: ${oraPass}"
echo "drop user tempuser;"
echo "############################################"
echo "then run following commands:"
echo "${sblHome}/siebsrvr/install_script/install/CreateDbSrvrEnvScript ${sblHome} ENU oracle"
echo "cd ${sblHome}/siebsrvr"
echo "chmod +x dbenv.sh"
echo ". ./dbenv.sh"
echo "cd ${sblHome}/config"
echo "bash  ./config.sh -mode dbsrvr"
echo "#############################################"
echo "or instead of above command you can run below script:"
echo "wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/SiebelPostInstall-21.7.sh"
echo "bash SiebelPostInstall-21.7.sh"
echo "after that open URL in SMC with address LIKE https://$(hostname -f):8443/siebel/smc/index.html"
