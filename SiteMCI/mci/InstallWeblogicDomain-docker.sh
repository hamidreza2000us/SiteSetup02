username=weblogic
password=welcome1
domain=mydomain
ssl=false
MSNumber=1
masterServer=localhost
adminPort=7001
ssloff="-e ADMINISTRATION_PORT_ENABLED='false'"
image=artifactory.idm.mci.ir/oracle/middleware/weblogic:12.2.1.4-220120
#docker pull container-registry.oracle.com/middleware/weblogic:14.1.1.0-11-ol8-220120	
#docker pull container-registry.oracle.com/middleware/weblogic:14.1.1.0-slim-11-ol8-220120

echo "In this installation only localhost selection would install master server"
read -rp "What is the IP address of master server : ($masterServer) " choice; [[ -n "${choice}"  ]] &&  export masterServer="$choice";
read -rp "What is the weblogic domain name : ($domain) " choice; [[ -n "${choice}"  ]] &&  export domain="$choice";
read -rp "What is the weblogic admin Username : ($username) " choice; [[ -n "${choice}"  ]] &&  export username="$choice";
read -rp "What is the weblogic admin Password : ($password) " choice; [[ -n "${choice}"  ]] &&  export password="$choice";
read -rp "How many Managed Server to create : ($MSNumber) " choice; [[ -n "${choice}"  ]] &&  export MSNumber="$choice";
#read -rp "Do you want to enable SSL true/false : ($ssl) " choice; [[ -n "${choice}"  ]] &&  export ssl="$choice";
echo "1) 14.1.1.0"
echo "2) 12.2.1.4"
weblogicVersion=1
read -rp "Which version of Oracle Weblogic do you want to install : ($weblogicVersion) " choice; [[ -n "${choice}"  ]] &&  export weblogicVersion="$choice";

case $weblogicVersion in
	1)
	    if [ ${masterServer} == "localhost"  ]
	    then
			image=artifactory.idm.mci.ir/oracle/middleware/weblogic:14.1.1.0-8-ol8-220120
	    else
			image=artifactory.idm.mci.ir/oracle/middleware/weblogic:14.1.1.0-slim-8-ol8-220120
		fi
	  ;;
	2)
		if [ ${masterServer} == "localhost"  ]
	    then
			image=artifactory.idm.mci.ir/oracle/middleware/weblogic:12.2.1.4-ol8-220120
	    else
			image=artifactory.idm.mci.ir/oracle/middleware/weblogic:12.2.1.4-slim-ol8-220120
		fi
	   
	  ;;
	*) 
	    if [ ${masterServer} == "localhost"  ]
	    then
			image=artifactory.idm.mci.ir/oracle/middleware/weblogic:12.2.1.4-ol8-220120
	    else
			image=artifactory.idm.mci.ir/oracle/middleware/weblogic:12.2.1.4-slim-ol8-220120
		fi
	   
	  ;;
esac

if [ ${ssl} == true ]
then
  ssloff=''
  adminPort=9002
fi

yum -y install podman policycoreutils-python

setenforce 0
mkdir -p /opt/weblogicdir
semanage fcontext -a -t container_file_t /opt/weblogicdir
restorecon -Rv /opt/weblogicdir

cat > /opt/weblogicdir/createMachine.py << EOF
connect(username,password,"t3://${masterServer}:${adminPort}")

import os

edit()
startEdit()

cd('/')
cmo.createUnixMachine("$(hostname -s)")

cd("/Machines/$(hostname -s)/NodeManager/$(hostname -s)")
cmo.setNMType('SSL')
cmo.setListenAddress('')
cmo.setListenPort(5556)
cmo.setDebugEnabled(false)


save()
activate()

EOF

cat > /opt/weblogicdir/createServer.py << EOF
connect(username,password,"t3://${masterServer}:${adminPort}")

import os
servers = cmo.getServers()
number_of_ms = len(servers)
#number_of_ms = int(sys.argv[1])
target = 'ms_' + str(number_of_ms)
port = 8000 + int(number_of_ms)
print('ManageServerID     : %s' % number_of_ms);

f = open("/tmp/MSID.txt", "w")
f.write(target)
f.close()

edit()
startEdit()


cd('/')
cmo.createServer(target)

cd('/Servers/' + target)
cmo.setListenAddress('')
cmo.setListenPort(port)
cmo.setMachine(getMBean("/Machines/$(hostname -s)"))

save()
activate()

start(target)
EOF

cat > /opt/weblogicdir/domain.properties << EOF
username=${username}
password=${password}
EOF

sleep 5

podman ps -a | grep -q wlsadmin
[ $? == 0 ] && podman rm -f wlsadmin

if [ ${ssl} == true ]
then
   podman run -d --name wlsadmin --hostname $(hostname -s) -p 9002:9002 -p 7001:7001 \
   -p 8001:8001 -p 8002:8002 -p 8003:8003 -p 8004:8004 -p 8005:8005 -p 8006:8006 -p 8007:8007 -p 8008:8008 -p 8009:8009 \
   -v /opt/weblogicdir/:/u01/oracle/properties -e ADMIN_PASSWORD=${password} -e DOMAIN_NAME=${domain} -e  PRODUCTION_MODE="prod" ${image}
else
   podman run -d --name wlsadmin --hostname $(hostname -s) -p 9002:9002 -p 7001:7001 \
   -p 8001:8001 -p 8002:8002 -p 8003:8003 -p 8004:8004 -p 8005:8005 -p 8006:8006 -p 8007:8007 -p 8008:8008 -p 8009:8009 \
   -v /opt/weblogicdir/:/u01/oracle/properties -e ADMIN_PASSWORD=${password} -e DOMAIN_NAME=${domain} -e  PRODUCTION_MODE="prod" -e ADMINISTRATION_PORT_ENABLED='false' ${image}
fi
 
action=started
while true
do
	sleep 5
	if [ "$action" == "started" ]; then
		#[ ${ssl} == true ] && started_url="https://localhost:${adminPort}/weblogic/ready" || started_url="http://localhost:${adminPort}/weblogic/ready"
		started_url="http://localhost:7001/weblogic/ready"
		echo -e "Waiting for WebLogic server to get $action, checking $started_url"
		status=`/usr/bin/curl -s -k -i $started_url | grep "200 OK"`
		echo "Status:" $status
		if [ ! -z "$status" ]; then
		  break
		fi
	fi
done

podman exec -it wlsadmin  wlst.sh -skipWLSModuleScanning -loadProperties properties/domain.properties /u01/oracle/properties/createMachine.py
podman exec  wlsadmin nohup /u01/oracle/user_projects/domains/${domain}/bin/startNodeManager.sh &> /dev/null &

for i in $(seq $[${MSNumber}])
do
	podman exec -it wlsadmin  wlst.sh -skipWLSModuleScanning -loadProperties properties/domain.properties /u01/oracle/properties/createServer.py
	#MSID=$(podman exec -it wlsadmin cat /tmp/MSID.txt)
	podman exec -it wlsadmin  mkdir -p /u01/oracle/user_projects/domains/${domain}/servers/${MSID}/security
	podman exec -it wlsadmin cp /u01/oracle/properties/domain.properties /u01/oracle/user_projects/domains/${domain}/servers/${MSID}/security/boot.properties
	#podman exec  wlsadmin nohup /u01/oracle/user_projects/domains/${domain}/bin/startManagedWebLogic.sh ${MSID} http://${masterServer}:${adminPort} &> /dev/null &
done
if [ ${masterServer} != "localhost"  ]
then
	podman exec  wlsadmin nohup /u01/oracle/user_projects/domains/${domain}/bin/stopWebLogic.sh &> /dev/null &
fi


podman generate systemd wlsadmin > /etc/systemd/system/wlsadmin.service
systemctl daemon-reload
systemctl  enable --now wlsadmin
systemctl  status wlsadmin
#MSID=ms_3; adminPort=7001; podman exec  wlsadmin nohup /u01/oracle/user_projects/domains/${domain}/bin/startManagedWebLogic.sh ${MSID} http://localhost:${adminPort} &> /dev/null &
#PRODUCTION_MODE}" = "true"