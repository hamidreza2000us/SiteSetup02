su - oracle
wget https://satellite.idm.mci.ir/pub/RHEL/Software/Slob/2021.05.12.slob_2.5.4.0.tar.gz 
tar -xvf 2021.05.12.slob_2.5.4.0.tar.gz
cd SLOB

tns=$(grep "^[[:alnum:]]" /u01/app/oracle/product/11.2.0/db_1/network/admin/tnsnames.ora  | awk '{print $1}')
cp slob.conf slob.conf.bkp
#https://infohub.delltechnologies.com/l/reference-architecture-guide-dell-emc-ready-solutions-for-oracle-design-for-unity-all-flash-storage/slob-parameter-settings-slob-conf-2
cat > slob.conf << EOF
#read/write
UPDATE_PCT=5
#random/sequentail
SCAN_PCT=0
RUN_TIME=60
#how many time to repeat each operation (zero)
WORK_LOOP=0
SCALE=9600M
SCAN_TABLE_SZ=1M
#test UNDO by select/update work_unit block together.
WORK_UNIT=6
#REDO_STRESS=HEAVY
REDO_STRESS=LITE
#loading concurrency (faster but affecting the temp tabelspace)
LOAD_PARALLEL_DEGREE=8
#implicate concurrency ; depending on cpu and memory and max file can be incresed
THREADS_PER_SCHEMA=128
DATABASE_STATISTICS_TYPE=awr   
ADMIN_SQLNET_SERVICE=$tns
SQLNET_SERVICE_BASE=$tns
#SQLNET_SERVICE_MAX=2
#DBA_PRIV_USER="ldtst"
#SYSDBA_PASSWD="ldtst#1400"
EXTERNAL_SCRIPT=""
DO_HOTSPOT=FALSE
HOTSPOT_MB=8
HOTSPOT_OFFSET_MB=16
HOTSPOT_FREQUENCY=3
HOT_SCHEMA_FREQUENCY=0
THINK_TM_FREQUENCY=0
THINK_TM_MIN=.1
THINK_TM_MAX=.5
EOF


#ask DBA to check the tnsnames in ADMIN_SQLNET_SERVICE and SQLNET_SERVICE_BASE with a tnsping and config
#then go on

#to set up the base user
sqlplus -s / as sysdba  << EOF
grant sysdba,dba,connect,resource  to system identified by manager;
EOF
sqlplus / as sysdba < misc/ts.sql

#to setup the test environment
sh ./setup.sh IOPS 16 
#20 mins for 16 * 10G parallel 4

#to compile the application
cd ./wait_kit/
make
cd ..

#to run the test
sh ./runit.sh 16

#to get awr result
cd /u01/app/oracle/product/11.2.0/db_1/rdbms/admin/
sqlplus / as sysdba
#@awrrpt.sql
@awrgrpt.sql
#system statistics


