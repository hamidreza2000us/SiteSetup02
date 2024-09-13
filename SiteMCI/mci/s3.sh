##radosgw-admin user create --uid="behsatest" --display-name="behsatest" --caps="users=read,write; usage=read,write; buckets=read,write; zone=read,write" --access_key="behsatest" --secret="behsatest"


#1-set /etc/hosts  or 2-use below dns servers or 3-you could simply join via freeipa (last item also automatically configure ssl )
#search idm.mci.ir
#nameserver 172.17.58.97
#nameserver 172.17.58.98
echo "172.18.27.1 tlb01.idm.mci.ir" >> /etc/hosts
echo "172.16.49.97 satellite.idm.mci.ir" >> /etc/hosts

#if you don't have the following packages in your repository do as below:
# subscription-manager unregister
# yum remove -y katello-ca-consumer*
# yum -y install  http://satellite.idm.mci.ir/pub/katello-ca-consumer-satellite.idm.mci.ir-1.0-2.noarch.rpm
#as per your product select one of the below activation key for your RHEL7 or RHEL8 environment
#for RHEL7:
# subscription-manager register --org="MCI" --activationkey="krh7"
#for RHEL8:
# subscription-manager register --org="MCI" --activationkey="kceph04"

yum -y install s3cmd

#if you need ssl you can issue the commands below:
# curl https://ipa01.idm.mci.ir/ipa/config/ca.crt -o /etc/pki/ca-trust/source/anchors/ca-ipa.crt
# update-ca-trust extract
#if you have selinux enabled
# restorecon -R /etc/pki/ca-trust/source/anchors/
#in command below add --ssl instead of --no-ssl if you have performed the tasks above, answer all question as their defaults but save the configuration (last item)
s3cmd --configure --access_key=behsatest --secret_key=behsatest   --host=tlb01.idm.mci.ir --host-bucket="tlb01.idm.mci.ir/%(bucket)" --no-encrypt --no-ssl

#use the command below as a sample file operation
echo "this is a test" > testfile
s3cmd put testfile s3://fms
s3cmd ls s3://fms
s3cmd get s3://fms/testfile testfilecopy
cat testfilecopy
s3cmd rm s3://fms/testfile
#if you need to have a file publicly available use command below
#s3cmd put --acl-public  testfile s3://fms



#curl format
file="/etc/services"
bucket=fms
resource="/${bucket}/${file}"
contentType="application/x-compressed-tar"
dateValue=`date -R --utc`
stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
s3Key=behsatest
s3Secret=behsatest
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
curl -X PUT -T "${file}" \
  -H "Host: tlb01.idm.mci.ir" \
  -H "Date: ${dateValue}" \
  -H "Content-Type: ${contentType}" \
  -H "Authorization: AWS ${s3Key}:${signature}" \
  http://tlb01.idm.mci.ir/${bucket}/${file}


resource="/"
s3Key=behsatest
s3Secret=behsatest
dateValue=`date -R --utc`
contentType="text/plain"
stringToSign="GET\n\n${contentType}\n${dateValue}\n${resource}"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`

curl  GET \
  -H "Host: tlb01.idm.mci.ir" \
  -H "Date: ${dateValue}" \
  -H "Content-Type: text/plain" \
  -H "Authorization: AWS ${s3Key}:${signature}" \
  http://tlb01.idm.mci.ir/
  


resource="/fms/services"
s3Key=behsatest
s3Secret=behsatest
dateValue=`date -R --utc`
contentType="text/plain"
stringToSign="GET\n\n${contentType}\n${dateValue}\n${resource}"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`

curl  GET \
  -H "Host: tlb01.idm.mci.ir" \
  -H "Date: ${dateValue}" \
  -H "Content-Type: text/plain" \
  -H "Authorization: AWS ${s3Key}:${signature}" \
  http://tlb01.idm.mci.ir${resource} 

echo -e ''


