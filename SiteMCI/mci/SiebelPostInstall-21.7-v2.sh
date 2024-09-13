#!/bin/bash

source /tmp/values
oraPass=${oraPass}
TablePassword=${oraPass}
sblHome=${sblHome}
userhomedir=$(eval echo ~$(whoami))

echo "This script must be run as siebel user"
echo "Perior to this step siebl installation (runInstaller) should be finished  "
echo "and ${sblHome}/dbsrvr/oracle/grantusr.sql must alrady run by DBA"
echo "Also make sure the table spaces are created and tns connection properly configured"

read -rp "What is the password for database username -> sadmin ($oraPass): " choice; [[ -n "${choice}"  ]] &&  export oraPass="$choice";
read -rp "What is the password for siebel table owner -> siebel ($TablePassword): " choice; [[ -n "${choice}"  ]] &&  export TablePassword="$choice";
read -rp "What is the home dir of siebel user ($sblHome): " choice; [[ -n "${choice}"  ]] &&  export sblHome="$choice";

cat >  ${userhomedir}/config.rsp << EOF
BaseLanguage=enu
BaseLanguageExists=BaseLanguageExists
ConfigAction=Install_Database
ConnectorDll=sscdo90
ConnectString=orcl
CPU=Single_CPU
CreateOrExistingEnterprise=CreateEnterprise
current_section=CommonParams
current_step=SiebelLogProcess
CurrentRegistryRoot=HKEY_LOCAL_MACHINE
DatabaseOwner=siebel
DatabasePlatform=oracle
DatabaseVersion=Oracle
DBConnectString=orcl
DbsrvrRoot=${sblHome}/dbsrvr
Dev2ProdSelectRepLocation=Dev2ProdExportFromSource
first_section=CommonParams
first_step=SiebelServerRootDbsrvrRoot
Grantee=SSE_ROLE
GrantstatPromptName=The GRANTUSR.SQL script must first be run by the database administrator (DBA) in order to  create the necessary Siebel users and roles before continuing.

HostName=$(hostname -f)
IdCentricRoot=IdCentricRoot
ImprepFileName=${sblHome}/dbsrvr/common/mstrep.dat
IndexSpace=SIEBEL_INDEX
InstallDir=${sblHome}/siebsrvr
InstallPromptName=This confirms that you wish to install a new Siebel database. Running this step against an existing Siebel database may make that database unusable.

InstallSelectAction=Install_Primary_Language
InstallType=NotApplicable
InstallUnicodeFlag=UNICODE
JTCHelpURL=JTCHelpURL
LangSeedFileName=${sblHome}/dbsrvr/ENU/seed_locale.dat
Language=ENU
LanguageTemp=enu
MainAction=Create
MasterFileName=master_install.ucf
MasterUCFFile=${sblHome}/dbsrvr/oracle/master_install.ucf
MaxCursorSize=-1
MSSQL_DRIVER_NAME=ODBC Driver 17 for SQL Server
ODBCDataSource=SiebelInstall_DSN
ODBCEntDriver=${sblHome}/siebsrvr/lib/SEor827.so
OperatingSystem=linux
OracleParallelIndex=N
OSDirSeparator=/
OSType=amd64
Password=${oraPass}
PrefetchSize=-1
ProcessName=install
RepFileName=${sblHome}/dbsrvr/common/mstrep.dat
RepositoryName=Siebel Repository
ResourceLanguage=ENU
SeedFileName=${sblHome}/dbsrvr/ENU/seed.dat
SelectAction=Install_Primary_Language
SiebelBinDir=${sblHome}/siebsrvr/bin
SiebelDbsrvrRoot=${sblHome}/dbsrvr
SiebelEncryption=
SiebelEnterprise=SiebelInstall
SiebelHome=${sblHome}
SiebeLibDir=${sblHome}/siebsrvr/lib
SiebelInstalledDir=${sblHome}/siebsrvr
SiebelLanguage=ENU
SiebelLogArch=
SiebelLogDir=${sblHome}/siebsrvr/log/install/output
SiebelLogEvents=3
SiebelLogFile=
SiebelLogProcess=install
SiebelMaxThreads=
SiebelMsgDir=${sblHome}/siebsrvr/locale/enu
SiebelPassword=
SiebelProgName=
SiebelRoot=${sblHome}/siebsrvr
SiebelServerRoot=${sblHome}/siebsrvr
SiebelTableOwner=
SiebelTempDir=${sblHome}/siebsrvr/temp
SiebelUser=
SiebelVersion=21.7.0.0SIA[2021_07]
SqlStyle=OracleCBO
TableOwner=siebel
TablePassword=${TablePassword}
TableSpace=SIEBEL_DATA
Trace=0
TraceDll=${sblHome}/siebsrvr/lib/SEtrc27.so
TraceFile=odbctrace.out
UnicodeEnable=
UnicodeFlag=Y
UnixOracleDb2DriverName=MERANT 7.1 Oracle 12 Driver
UpglocaleFile=${sblHome}/dbsrvr/ENU/upglocale.enu
UseOracleConnector=true
UserName=sadmin
EOF

${sblHome}/siebsrvr/install_script/install/CreateDbSrvrEnvScript ${sblHome} ENU oracle
cd ${sblHome}/siebsrvr
chmod +x dbenv.sh
. ./dbenv.sh
cd ${sblHome}/config
#bash  ./config.sh -mode dbsrvr
bash  ./config.sh -mode dbsrvr  -responseFile ${userhomedir}/config.rsp
time ${sblHome}/siebsrvr/bin/srvrupgwiz /m ${sblHome}/siebsrvr/bin/master_install.ucf 

cat > ${userhomedir}/config-addarabic.rsp << EOF

ConfigAction=Import_Repository
CPU=Single_CPU
CreateOrExistingEnterprise=CreateEnterprise
current_section=CommonParams
current_step=SiebelLogProcess
DatabaseOwner=siebel
DatabasePlatform=oracle
DatabaseVersion=Oracle
DbsrvrRoot=${sblHome}/dbsrvr
Dev2ProdSelectRepLocation=Dev2ProdExportFromSource
first_section=CommonParams
first_step=SiebelServerRootDbsrvrRoot
Grantee=SSE_ROLE
HostName=siebel01.idm.mci.ir
IdCentricRoot=IdCentricRoot
ImportRepositorySelectAction=Import_Repository_Additional_Language
ImprepLangUnicodeFlag=UNICODE
JTCHelpURL=JTCHelpURL
LangImprepFileName=${sblHome}/dbsrvr/common/mstrep.dat
LangRepFileName=${sblHome}/dbsrvr/common/mstrep.dat
Language=ara
LanguageImprep=ara
LanguageImprepUpper=ARA
LanguageTemp=ara
MainAction=Create
MasterFileName=master_imprep_lang.ucf
MasterUCFFile=${sblHome}/dbsrvr/oracle/master_imprep_lang.ucf
MSSQL_DRIVER_NAME=ODBC Driver 17 for SQL Server
ODBCDataSource=SiebelInstall_DSN
ODBCEntDriver=${sblHome}/siebsrvr/lib/SEor827.so
OperatingSystem=linux
OracleParallelIndex=N
OSDirSeparator=/
OSType=amd64
Password=${oraPass}
ProcessName=imprep_lang
RepositoryName=Siebel Repository
ResourceLanguage=ENU
SelectAction=Import_Repository_Additional_Language
SiebelBinDir=${sblHome}/siebsrvr/bin
SiebelDbsrvrRoot=${sblHome}/dbsrvr
SiebelEncryption=
SiebelHome=${sblHome}
SiebeLibDir=${sblHome}/siebsrvr/lib
SiebelInstalledDir=${sblHome}/siebsrvr
SiebelLanguage=ENU
SiebelLogArch=
SiebelLogDir=${sblHome}/siebsrvr/log/imprep_lang/output
SiebelLogEvents=3
SiebelLogFile=
SiebelLogProcess=imprep_lang
SiebelMaxThreads=
SiebelMsgDir=${sblHome}/siebsrvr/locale/enu
SiebelPassword=
SiebelProgName=
SiebelRoot=${sblHome}/siebsrvr
SiebelServerRoot=${sblHome}/siebsrvr
SiebelTableOwner=
SiebelTempDir=${sblHome}/siebsrvr/temp
SiebelUser=
SiebelVersion=21.7.0.0SIA[2021_07]
TableOwner=siebel
TablePassword=${TablePassword}
UnicodeEnable=
UnicodeFlag=Y
UpglocaleFile=${sblHome}/dbsrvr//upglocale.ara
UserName=sadmin
EOF

#cd ${sblHome}/siebsrvr
#chmod +x dbenv.sh
#. ./dbenv.sh
cd ${sblHome}/config
bash  ./config.sh -mode dbsrvr  -responseFile ${userhomedir}/config-addarabic.rsp
time ${sblHome}/siebsrvr/bin/srvrupgwiz /m /u01/app/siebel/siebsrvr/bin/master_imprep_lang.ucf


