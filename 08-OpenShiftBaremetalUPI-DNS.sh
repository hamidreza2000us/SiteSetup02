IDMIP=192.168.1.112
IDMPASS=Iahoora@123
Domain=myhost.com.
OpenshiftSub=openshift02
PTRDomain=1.168.192.in-addr.arpa.


export API_IP=192.168.1.230
export API_DNS=api.${OpenshiftSub}
export APIINT_IP=192.168.1.230
export APIINT_DNS=api-int.${OpenshiftSub}
export APPS_IP=192.168.1.230
export APPS_DNS=*.apps.${OpenshiftSub}
export MASTER0_IP=192.168.1.231
export MASTER0_DNS=master0.${OpenshiftSub}
export MASTER1_IP=192.168.1.232
export MASTER1_DNS=master1.${OpenshiftSub}
export MASTER2_IP=192.168.1.233
export MASTER2_DNS=master2.${OpenshiftSub}
export COMPUTE0_IP=192.168.1.234
export COMPUTE0_DNS=compute0.${OpenshiftSub}
export COMPUTE1_IP=192.168.1.235
export COMPUTE1_DNS=compute1.${OpenshiftSub}
export BOOTSTRAP_IP=192.168.1.236
export BOOTSTRAP_DNS=bootstrap.${OpenshiftSub}


ssh-keygen -t rsa -b 4096 -N '' -f /root/.ssh/id_rsa
eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_rsa
ssh-copy-id  -o StrictHostKeyChecking=no  -i /root/.ssh/id_rsa.pub  ${IDMIP}

ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${BOOTSTRAP_DNS} --a-rec ${BOOTSTRAP_IP} --a-create-reverse "
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${API_DNS} --a-rec ${API_IP} --a-create-reverse "

ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${MASTER0_DNS} --a-rec ${MASTER0_IP} --a-create-reverse "
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${MASTER1_DNS} --a-rec ${MASTER1_IP} --a-create-reverse "
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${MASTER2_DNS} --a-rec ${MASTER2_IP} --a-create-reverse "
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${COMPUTE0_DNS} --a-rec ${COMPUTE0_IP} --a-create-reverse "
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${COMPUTE1_DNS} --a-rec ${COMPUTE1_IP} --a-create-reverse "



ReverseIP=$(echo ${APIINT_IP} | awk -F. '{print $3"."$2"."$1".in-addr.arpa."}')

IPPart=$(echo ${APIINT_IP} | awk -F. '{print $4}')
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${APIINT_DNS} --a-rec ${APIINT_IP} "
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${ReverseIP} ${IPPart} --ptr-rec ${APIINT_DNS}.${Domain} "

IPPart=$(echo ${APPS_IP} | awk -F. '{print $4}')
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${Domain} ${APPS_DNS} --a-rec ${APPS_IP} "
ssh ${IDMIP} "echo ${IDMPASS} | kinit admin; ipa dnsrecord-add ${ReverseIP} ${IPPart} --ptr-rec ${APPS_DNS}.${Domain} "



