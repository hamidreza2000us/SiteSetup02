#this script assumes that you have an online satellite server inside DMZ and another offline satellite server inside DC
#this will once sync the content to the online version and then sync the content to offline repository
#both satellite servers need manifest installed. use the minimum amount of subscription in online version and use the rest in offline version
#identify the repositories to subscribe

ORGID=1

#FIXME: better to integrate GPGkeys with repos??!
unset GPGMatrix
declare -A GPGMatrix
GPGMatrix[0,0]='Name'
GPGMatrix[0,1]='URL'
GPGMatrix[1,0]='Cent7GPG'
GPGMatrix[1,1]='http://mirror.centos.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7'
GPGMatrix[2,0]='EPEL7GPG'
GPGMatrix[2,1]='https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7Server'
GPGMatrix[3,0]='ELKGPG'
GPGMatrix[3,1]='https://artifacts.elastic.co/GPG-KEY-elasticsearch'
GPGMatrix[4,0]='KuberGPG'
GPGMatrix[4,1]='https://packages.cloud.google.com/yum/doc/yum-key.gpg'
GPGMatrix[5,0]='ZabbixGPG'
GPGMatrix[5,1]='https://repo.zabbix.com/zabbix-official-repo.key'
GPGMatrix[6,0]='Cent8GPG'
GPGMatrix[6,1]='http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official'
GPGMatrix[7,0]='EPEL8GPG'
GPGMatrix[7,1]='https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'

#FIXME: automatic number for rows here
GPGMatrixRows=7

#FIXME: don't add duplicated keys
for i in $(seq ${GPGMatrixRows})
do
	curl ${GPGMatrix[$i,1]} -o /tmp/"${GPGMatrix[$i,0]}"
    hammer content-credentials create --organization-id ${ORGID}  --name "${GPGMatrix[$i,0]}" --key /tmp/"${GPGMatrix[$i,0]}" --content-type gpg_key
done

unset RepoMatrix
declare -A RepoMatrix
RepoMatrix[0,0]='Product'
RepoMatrix[0,1]='RepoName'
RepoMatrix[0,2]='URL'
RepoMatrix[0,3]='GPGKEY'
RepoMatrix[1,0]='Cent8'
RepoMatrix[1,1]='BaseOS'
RepoMatrix[1,2]='http://mirror.centos.org/centos/8/BaseOS/'
RepoMatrix[1,3]='Cent8GPG'
RepoMatrix[2,0]='Cent8'
RepoMatrix[2,1]='AppStream'
RepoMatrix[2,2]='http://mirror.centos.org/centos/8/AppStream/'
RepoMatrix[2,3]='Cent8GPG'
RepoMatrix[3,0]='Cent8'
RepoMatrix[3,1]='HA'
RepoMatrix[3,2]='http://mirror.centos.org/centos/8/HighAvailability/x86_64/os/'
RepoMatrix[3,3]='Cent8GPG'
RepoMatrix[4,0]='Cent8'
RepoMatrix[4,1]='PowerTools'
RepoMatrix[4,2]='http://mirror.centos.org/centos/8/PowerTools/x86_64/os/'
RepoMatrix[4,3]='Cent8GPG'
RepoMatrix[5,0]='Cent8'
RepoMatrix[5,1]='CentOSPlus'
RepoMatrix[5,2]='http://mirror.centos.org/centos/8/centosplus/x86_64/os/'
RepoMatrix[5,3]='Cent8GPG'
RepoMatrix[6,0]='Cent8'
RepoMatrix[6,1]='Extras'
RepoMatrix[6,2]='http://mirror.centos.org/centos/8/extras/x86_64/os/'
RepoMatrix[6,3]='Cent8GPG'
RepoMatrix[7,0]='Cent8'
RepoMatrix[7,1]='qpid-proton'
RepoMatrix[7,2]='http://mirror.centos.org/centos/8/messaging/x86_64/qpid-proton/'
RepoMatrix[7,3]='Cent8GPG'
RepoMatrix[8,0]='Cent8'
RepoMatrix[8,1]='RabbitMQ'
RepoMatrix[8,2]='http://mirror.centos.org/centos/8/messaging/x86_64/rabbitmq-38/'
RepoMatrix[8,3]='Cent8GPG'
RepoMatrix[9,0]='Cent8'
RepoMatrix[9,1]='EPEL-Everything'
RepoMatrix[9,2]='https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/'
RepoMatrix[9,3]='EPEL8GPG'
RepoMatrix[10,0]='Cent8'
RepoMatrix[10,1]='EPEL-Modular'
RepoMatrix[10,2]='https://dl.fedoraproject.org/pub/epel/8/Modular/x86_64/'
RepoMatrix[10,3]='EPEL8GPG'
RepoMatrix[11,0]='Cent8'
RepoMatrix[11,1]='Zabbix'
RepoMatrix[1,2]='https://repo.zabbix.com/zabbix/5.4/rhel/8/x86_64/'
RepoMatrix[11,3]='ZabbixGPG'

#FIXME: automatic number of rows
RepoMatrixRows=11

for i in $(seq 1 ${RepoMatrixRows})
do
    ProductID=$(hammer --output csv  product list  --organization-id ${ORGID} --name "${RepoMatrix[$i,0]}" | tail -n -1  | awk -F, '{print $1}')
    if [ "${ProductID}" == "ID" ]
    then
        SyncID=$(hammer  --output csv  --no-headers  sync-plan list  --organization-id  ${ORGID} --name 'daily' | awk -F, '{print $1}' )
	    hammer product create --organization-id ${ORGID} --name "${RepoMatrix[$i,0]}" ----sync-plan-id ${SyncID}
        ProductID=$(hammer --output csv  product list  --organization-id ${ORGID} --name "${RepoMatrix[$i,0]}" | tail -n -1  | awk -F, '{print $1}')
    fi
	
    #FIXME: don't add a repo twice
	#FIXME: update the new values anyway?!
    hammer repository create --product-id ${ProductID} --content-type yum --download-policy immediate --mirror-on-sync no --organization-id ${ORGID} --name \
 "${RepoMatrix[$i,1]}" --url  "${RepoMatrix[$i,2]}" --gpg-key "${RepoMatrix[$i,3]}"
    hammer repository sync --organization-id ${ORGID} --product-id ${ProductID}  --name "${RepoMatrix[$i,1]}"  --async
done

echo -n '' > /tmp/contentIDs
for i in $(seq 1 ${RepoMatrixRows})
do
    ContentID=$(hammer --output csv  content-view list  --organization-id ${ORGID} --name "V${RepoMatrix[$i,0]}" | tail -n -1  | awk -F, '{print $1}')
    if [ "${ContentID}" == 'Content View ID' ]
    then
        hammer content-view create --organization-id ${ORGID} --name "V${RepoMatrix[$i,0]}" --label "V${RepoMatrix[$i,0]}"
        ContentID=$(hammer --output csv  content-view list  --organization-id ${ORGID} --name "V${RepoMatrix[$i,0]}" | tail -n -1  | awk -F, '{print $1}')
        hammer content-view publish --id ${ContentID} --organization-id ${ORGID} 
        hammer activation-key create --name "K${RepoMatrix[$i,0]}" --organization-id ${ORGID} --lifecycle-environment Library --content-view-id ${ContentID} 
        hammer activation-key update --name "K${RepoMatrix[$i,0]}"  --auto-attach false --organization-id ${ORGID}
        subsID=$(hammer --output csv --no-headers  subscription list | grep ","${RepoMatrix[$i,0]}"," | awk -F, '{print $1}')
        hammer activation-key add-subscription --name "K${RepoMatrix[$i,0]}" --subscription-id ${subsID}  --organization-id ${ORGID}    
    fi
	#FIXME: don't try to add a repo twice to a content
	echo "${ContentID}" >> /tmp/contentIDs
    hammer content-view add-repository --id  "${ContentID}"  --product "${RepoMatrix[$i,0]}" --organization-id ${ORGID} --repository "${RepoMatrix[$i,1]}"
done

cat /tmp/contentIDs | sort | uniq | grep -v "^$"  > /tmp/uniqcontentIDs
while read id
do
   hammer content-view publish --id $id --organization-id ${ORGID}  --async
done < /tmp/uniqcontentIDs
rm -rf /tmp/contentIDs /tmp/uniqcontentIDs 
##################################################################################

######################################
#Rows=8
#Columns=2
#for i in $(seq ${Rows})
#do
#    for j in $(seq 0 ${Columns})
#    do
#         echo "${GPGMatrix[$i,$j]}"
#    done
#done
######################################