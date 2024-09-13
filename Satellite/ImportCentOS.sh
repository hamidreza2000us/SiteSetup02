#this script assumes that you have an online satellite server inside DMZ and another offline satellite server inside DC
#this will once sync the content to the online version and then sync the content to offline repository
#both satellite servers need manifest installed. use the minimum amount of subscription in online version and use the rest in offline version
#identify the repositories to subscribe

ORGID=1

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

GPGMatrixRows=7

for i in $(seq ${GPGMatrixRows})
do
	curl ${GPGMatrix[$i,1]} -o /tmp/"${GPGMatrix[$i,0]}"
    hammer content-credentials create --organization-id ${ORGID}  --name "${GPGMatrix[$i,0]}" --key /tmp/"${GPGMatrix[$i,0]}" --content-type gpg_key
done


declare -A RepoMatrix
RepoMatrix[0,0]='Product'
RepoMatrix[0,1]='RepoName'
RepoMatrix[0,2]='URL'
RepoMatrix[0,3]='GPGKEY'
RepoMatrix[1,0]='Cent7'
RepoMatrix[1,1]='CentOS 7 OS'
RepoMatrix[1,2]='http://mirror.centos.org/centos/7/os/x86_64/'
RepoMatrix[1,3]='Cent7GPG'
RepoMatrix[2,0]='Cent7'
RepoMatrix[2,1]='qpid-dispatch'
RepoMatrix[2,2]='http://mirror.centos.org/centos/7/messaging/x86_64/qpid-dispatch/'
RepoMatrix[2,3]='Cent7GPG'
RepoMatrix[3,0]='Cent7'
RepoMatrix[3,1]='qpid-proton'
RepoMatrix[3,2]='http://mirror.centos.org/centos/7/messaging/x86_64/qpid-proton/'
RepoMatrix[3,3]='Cent7GPG'
RepoMatrix[4,0]='Cent7'
RepoMatrix[4,1]='opstools'
RepoMatrix[4,2]='http://mirror.centos.org/centos/7/opstools/x86_64/'
RepoMatrix[4,3]='Cent7GPG'
RepoMatrix[5,0]='Cent7'
RepoMatrix[5,1]='scl'
RepoMatrix[5,2]='http://mirror.centos.org/centos/7/sclo/x86_64/rh/'
RepoMatrix[5,3]='Cent7GPG'
RepoMatrix[6,0]='Cent7'
RepoMatrix[6,1]='extras'
RepoMatrix[6,2]='http://mirror.centos.org/centos/7/extras/x86_64/'
RepoMatrix[6,3]='Cent7GPG'
RepoMatrix[7,0]='Cent7'
RepoMatrix[7,1]='centosplus'
RepoMatrix[7,2]='http://mirror.centos.org/centos/7/centosplus/x86_64/'
RepoMatrix[7,3]='Cent7GPG'
RepoMatrix[8,0]='Cent7'
RepoMatrix[8,1]='ansible-29'
RepoMatrix[8,2]='http://mirror.centos.org/centos/7/configmanagement/x86_64/ansible-29/'
RepoMatrix[8,3]='Cent7GPG'
RepoMatrix[9,0]='Cent7'
RepoMatrix[9,1]='dotnet'
RepoMatrix[9,2]='http://mirror.centos.org/centos/7/dotnet/x86_64/Packages/'
RepoMatrix[9,3]='Cent7GPG'
RepoMatrix[10,0]='Cent7'
RepoMatrix[10,1]='epel'
RepoMatrix[10,2]='https://dl.fedoraproject.org/pub/epel/7Server/x86_64/'
RepoMatrix[10,3]='EPEL7GPG'
RepoMatrix[11,0]='Cent7'
RepoMatrix[11,1]='zabbix'
RepoMatrix[11,2]='https://repo.zabbix.com/zabbix/5.4/rhel/7/x86_64/'
RepoMatrix[11,3]='ZabbixGPG'
RepoMatrix[12,0]='Cent7'
RepoMatrix[12,1]='kubernetes'
RepoMatrix[12,2]='https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64'
RepoMatrix[12,3]='KuberGPG'
RepoMatrix[13,0]='Cent7'
RepoMatrix[13,1]='elastic'
RepoMatrix[13,2]='https://artifacts.elastic.co/packages/7.x/yum'
RepoMatrix[13,3]='ELKGPG'

RepoMatrixRows=13

for i in $(seq 1 ${RepoMatrixRows})
do
    ProductID=$(hammer --output csv  product list  --organization-id ${ORGID} --name "${RepoMatrix[$i,0]}" | tail -n -1  | awk -F, '{print $1}')
    if [ "${ProductID}" == "ID" ]
    then
	    hammer product create --organization-id ${ORGID} --name "${RepoMatrix[$i,0]}"
        ProductID=$(hammer --output csv  product list  --organization-id ${ORGID} --name "${RepoMatrix[$i,0]}" | tail -n -1  | awk -F, '{print $1}')
    fi
    
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
	echo "${ContentID}" >> /tmp/contentIDs
    hammer content-view add-repository --id  "${ContentID}"  --product "${RepoMatrix[$i,0]}" --organization-id ${ORGID} --repository "${RepoMatrix[$i,1]}"
done

cat /tmp/contentIDs | sort | uniq > /tmp/contentIDs
while read id
do
   hammer content-view publish --id $id --organization-id ${ORGID}  --async
done < /tmp/contentIDs

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