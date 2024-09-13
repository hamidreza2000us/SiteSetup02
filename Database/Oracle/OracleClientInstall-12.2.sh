oraRoot=/u01/app
oraBase=/u01/app/oracle
oraHome=${oraBase}/product/12.2.0/client_1
oraSource=http://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/p33094916_2100_Linux-x86-64_5of6.zip 


if ([ ! -z ${automated} ] && [ "${automated}" != 'true' ])
 then
	if ([ ! -z ${siebelUserInherit} ] && [ "${siebelUserInherit}" != 'true' ])
	then
		oraUser=siebel
		oraPass=ahoora
		read -rp "What is the username to use for oracle client: ($oraUser) " choice; [[ -n "${choice}"  ]] &&  export oraUser="$choice";
		read -rp "What is the password to use for oracle client: ($oraPass) " choice; [[ -n "${choice}"  ]] &&  export oraPass="$choice";
		echo "export oraUser=\"${oraUser}\"" >> /tmp/values
		echo "export oraPass=\"${oraPass}\"" >> /tmp/values
	fi 
	dbhost=''
	tnsport=1521
	srvname='orcl'
	read -rp "What is the hostname/ip of database: ($dbhost) " choice; [[ -n "${choice}"  ]] &&  export dbhost="$choice";
	read -rp "What is the tns port of database: ($tnsport) " choice; [[ -n "${choice}"  ]] &&  export tnsport="$choice";
	read -rp "What is the SERVICE_NAME of database: ($srvname) " choice; [[ -n "${choice}"  ]] &&  export srvname="$choice";
	echo "export dbhost=\"${dbhost}\"" >> /tmp/values
	echo "export tnsport=\"${tnsport}\"" >> /tmp/values
	echo "export srvname=\"${srvname}\"" >> /tmp/values
	echo "export oraRoot=\"${oraRoot}\"" >> /tmp/values
	echo "export oraBase=\"${oraBase}\"" >> /tmp/values
	echo "export oraHome=\"${oraHome}\"" >> /tmp/values

fi
if ! id ${oraUser} &>/dev/null;
then     
   groupadd oinstall ;
   useradd -m -g oinstall -G oinstall ${oraUser} 
   echo -n ${oraPass} | passwd --stdin ${oraUser}
   chmod 600 /tmp/values
   chown ${oraUser} /tmp/values
fi
#groupadd -g 54321 oinstall
#useradd -g oinstall ${oraUser}

#yum install -y binutils compat-libcap1  compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libgcc libstdc++ libstdc++-devel libaio libaio-devel libXext libXtst libX11 libXau libxcb libXi make sysstat libXmu libXt libXv libXxf86dga libdmx libXxf86misc libXxf86vm xorg-x11-utils xorg-x11-xauth nfs-utils smartmontools elfutils-libelf-devel ksh mksh
#yum install -y glibc-2.17-325.el7_9.i686 libXext.x86_64 libXrender.x86_64  libXext.i686 libXrender-0.9.10-1.el7.i686 libXtst-1.2.3-1.el7.i686 libgcc-4.8.5-44.el7.i686 libaio-0.3.109-13.el7.i686  libstdc++-4.8.5-44.el7.i686 
yum install -y elfutils-libelf-devel xorg-x11-utils
yum install -y bc gcc gcc-c++ binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 glibc.i686 glibc.x86_64 glibc-devel.i686 glibc-devel.x86_64 ksh libaio.i686 libaio.x86_64 libaio-devel.i686 libaio-devel.x86_64 libgcc.i686 libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.i686 libstdc++-devel.x86_64 libxcb.i686 libxcb.x86_64 libX11.i686 libX11.x86_64 libXau.i686 libXau.x86_64 libXi.i686 libXi.x86_64 libXtst.i686 libXtst.x86_64 libXrender.i686 libXrender.x86_64 libXrender.i686 libXrender.x86_64 make.x86_64 net-tools.x86_64 nfs-utils smartmontools.x86_64 sysstat.x86_64
ldconfig

mkdir -p ${oraBase}
chown ${oraUser}:oinstall /u01 

echo "${oraUser} ALL=(root) NOPASSWD:${oraRoot}/oraInventory/orainstRoot.sh" >> /etc/sudoers.d/${oraUser}.conf

userhomedir=$(eval echo ~${oraUser})
cat > ${userhomedir}/.bash_profile << 'EOF'
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
export TEMP=/tmp
export TMPDIR=/tmp

JAVA_HOME=/usr/bin/java; export JAVA_HOME
export ORACLE_TERM=xterm
NLS_DATE_FORMAT="DD-MON-YYYY HH24:MI:SS"
export NLS_DATE_FORMAT

export ORACLE_BASE=oraBase;
export ORACLE_HOME=oraHome; 

export ORACLE_HOSTNAME=oraHost

LD_LIBRARY_PATH=$ORACLE_HOME/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH

CLASSPATH=$ORACLE_HOME/JRE
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export CLASSPATH

export RESOLV_MULTI=off
export ORACLE_UNQNAME=oraUniq

export PATH=$ORACLE_HOME/bin:$PATH; 
export LANG=AMERICAN_AMERICA.AL32UTF8
EOF

sed  "s|oraBase|${oraBase}|g" -i ${userhomedir}/.bash_profile
sed  "s|oraHome|${oraHome}|g" -i ${userhomedir}/.bash_profile
sed  "s|oraHost|${dbhost}|g" -i ${userhomedir}/.bash_profile
sed  "s|oraUniq|${srvname}|g" -i ${userhomedir}/.bash_profile

mkdir -p ${oraRoot}/software
wget  ${oraSource} -P ${oraRoot}/software
chown -R ${oraUser}:oinstall ${oraRoot}

sudo -u ${oraUser}  cat > ${userhomedir}/client.rsp << EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_clientinstall_response_schema_v12.2.0
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=${oraRoot}/oraInventory
ORACLE_HOME=${oraHome}
ORACLE_BASE=${oraBase}
oracle.install.client.installType=Administrator
oracle.install.client.customComponents=
oracle.install.client.schedulerAgentHostName=
oracle.install.client.schedulerAgentPortNumber=
EOF

cd ${oraRoot}/software
sudo -u ${oraUser} unzip ${oraRoot}/software/$(basename ${oraSource} )
#mv Disk1 /dbclient/ora12client/product/12.1.0
#mv /dbclient/ora12client/product/12.1.0/Oracle_Database_Client ${oraHome} 
#cd ${oraHome}

cd ${oraRoot}/software/Disk1/Oracle_Database_Client
chmod -R 755 ${oraRoot}/software/Disk1/Oracle_Database_Client
#chmod +x /u01/stage/Disk1/Oracle_Database_Client/install/unzip
#chmod +x /u01/stage/Disk1/Oracle_Database_Client/install/*.sh
#chmod -R 777  /u01/stage/Disk1/Oracle_Database_Client/install/.oui
#chmod +x /u01/stage/Disk1/Oracle_Database_Client/install/runInstaller.sh
#setfacl -R -m  u:siebel:rwx /tmp/

#chown ${oraUser}:oinstall /tmp/Disk1/Oracle_Database_Client
#chown ${oraUser}:oinstall ${oraRoot}
#chown ${oraUser}:oinstall /home/${oraUser}/*
chmod +x ./runInstaller
#/u01/app/dbclient/product/12.2.0/client_1
sudo -u ${oraUser} ${oraRoot}/software/Disk1/Oracle_Database_Client/runInstaller  -silent -ignorePrereq -waitforcompletion -showProgress -responseFile ${userhomedir}/client.rsp
${oraRoot}/oraInventory/orainstRoot.sh

wget https://satellite.idm.mci.ir/pub/RHEL/Oracle/siebel/21.7/scripts/sqlnet.ora -P  ${oraHome}/network/admin/

sudo -u ${oraUser} cat >> ${oraHome}/network/admin/tnsnames.ora << EOF
ORCL =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${dbhost} )(PORT = ${tnsport} ))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${srvname} )
    )
  )
EOF
su  ${oraUser} -c "source ~/.bash_profile;  ${oraHome}/bin/tnsping ORCL"
#su - ${oraUser}


   
