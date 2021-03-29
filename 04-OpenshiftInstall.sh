IP1=192.168.1.200
IP2=192.168.1.201
IP3=192.168.1.202
IDMIP=192.168.1.112
GWIP=192.168.1.155
QuayIP=192.168.1.221

con=$( nmcli -g UUID,type con sh --active | grep ethernet | awk -F: '{print $1}' | head -n1)
IP=$(nmcli con sh "$con" | grep IP4.ADDRESS | awk '{print $2}')
GW=$(nmcli con sh "$con" | grep IP4.GATEWAY | awk '{print $2}')
DNS=$(nmcli con sh "$con" | grep IP4.DNS | awk '{print $2}')
nmcli con mod "$con" ipv4.method manual ipv4.addresses $IP  ipv4.dns ${IDMIP} ipv4.gateway ${GWIP} connection.autoconnect yes
nmcli con up "$con"
sleep 3
curl ipinfo.io/country


curl -k 'https://rhvm.myhost.com/ovirt-engine/services/pki-resource?resource=ca-certificate&format=X509-PEM-CA' -o /tmp/ca.pem
sleep 5
chmod 0644 /tmp/ca.pem
cp -p /tmp/ca.pem /etc/pki/ca-trust/source/anchors/
update-ca-trust

ssh-keygen -t rsa -b 4096 -N '' -f /root/.ssh/id_rsa
eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_rsa

mkdir Openshift
cd Openshift
#curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/openshift-install-linux.tar.gz -o openshift-install-linux.tar.gz 
curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/pull-secret.txt -o pull-secret.txt
curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz
tar xvf openshift-client-linux.tar.gz
mv oc /usr/local/bin/

yum -y install sshpass
sshpass -p ahoora scp  -o StrictHostKeyChecking=no  ${QuayIP}:/root/rootCA.pem /etc/pki/ca-trust/source/anchors/quay.ca
update-ca-trust
#echo -n | openssl s_client -connect quay.myhost.com:443     | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/quay.cert

export LOCAL_SECRET_JSON='pull-secret.txt'
export REMOVABLE_MEDIA_PATH=/repos
export PRODUCT_REPO='openshift-release-dev'
export RELEASE_NAME="ocp-release"
export OCP_RELEASE=4.6.8
export ARCHITECTURE=x86_64
export LOCAL_REGISTRY='quay.myhost.com'
export LOCAL_REPOSITORY='ocp468/testrepo'
oc adm release extract -a ${LOCAL_SECRET_JSON} --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}"

#tar xvf openshift-install-linux.tar.gz
mv openshift-install /usr/local/bin/

mkdir -p /root/.cache/openshift-installer/image_cache/
sshpass -p ahoora scp -o StrictHostKeyChecking=no  rhvh01.myhost.com:/mnt/Mount/Files/OpenShift/bf57d087842dfffd400c0048c17dfd97 /root/.cache/openshift-installer/image_cache/

##################################
mkdir /root/.ovirt
cat > /root/.ovirt/ovirt-config.yaml << EOF
ovirt_url: https://rhvm.myhost.com:443/ovirt-engine/api
ovirt_fqdn: rhvm.myhost.com:443
ovirt_pem_url: https://rhvm.myhost.com:443/ovirt-engine/services/pki-resource?resource=ca-certificate&format=X509-PEM-CA
ovirt_username: admin@internal
ovirt_password: ahoora
ovirt_ca_bundle: |-
EOF
while read line ; do echo "  $line" >> /root/.ovirt/ovirt-config.yaml ; done < /tmp/ca.pem
##################################

##################################
PUBKEY=$(cat /root/.ssh/id_rsa.pub)
mkdir /opt/OpenShift
cat >  /opt/OpenShift/install-config.yaml << EOF
apiVersion: v1
baseDomain: myhost.com
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: openshift01
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  ovirt:
    api_vip: 192.168.1.200
    ingress_vip: 192.168.1.201
    dns_vip: 192.168.1.202
    ovirt_cluster_id: 7a714758-4079-11eb-92e0-00163e1396bd
    ovirt_network_name: ovirtmgmt
    ovirt_storage_domain_id: 3304dbb0-8a06-448a-add4-88f1d5a684f6
    vnicProfileID: 0000000a-000a-000a-000a-000000000398
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"registry.connect.redhat.com":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"},"registry.redhat.io":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"}}}'
sshKey: ${PUBKEY}
publish: External
additionalTrustBundle: | 
EOF
while read line ; do echo "  $line" >> /opt/OpenShift/install-config.yaml ; done < /etc/pki/ca-trust/source/anchors/quay.ca
cat >> /opt/OpenShift/install-config.yaml << EOF
imageContentSources:
- mirrors:
  - quay.myhost.com/ocp468/testrepo
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - quay.myhost.com/ocp468/testrepo
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF
##############################

#export OPENSHIFT_INSTALL_OS_IMAGE_OVERRIDE=templateName
#unset SSH_AUTH_SOCK
openshift-install create install-config --dir=/opt/OpenShift/
#openshift-install create ignition-configs  --dir=/opt/OpenShift/
openshift-install create cluster --dir=/opt/OpenShift --log-level=info

#openshift-install wait-for bootstrap-complete --dir=/opt/OpenShift --log-level=debug
#openshift-install wait-for install-complete --dir=/opt/OpenShift --log-level=debug
#openshift-install destroy cluster --dir=/opt/OpenShift

#on rvhm if image transfer failed
#engine-config -g TransferImageClientInactivityTimeoutInSeconds
#engine-config -s TransferImageClientInactivityTimeoutInSeconds=300

#notes
#https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.6/
#https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.6/release.txt
#./openshift-install create manifests --dir /opt/OpenShift/
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. api.openshift01 --a-rec 192.168.1.200 --a-create-reverse '
ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. api-int.openshift01 --a-rec 192.168.1.200 --a-create-reverse '
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. *.apps.openshift01 --a-rec 192.168.1.201 '
##ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add 1.168.192.in-addr.arpa. 201 --ptr-rec *.apps.openshift01.myhost.com. '
##ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add 1.168.192.in-addr.arpa. 200 --ptr-rec api.openshift01.myhost.com. '
############################################################################################
#podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf

echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. api.openshift01 --a-rec 192.168.1.200 --a-create-reverse
echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. api-int.openshift01 --a-rec 192.168.1.200 
echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. *.apps.openshift01 --a-rec 192.168.1.201 


export KUBECONFIG=/opt/OpenShift/auth/kubeconfig

: '
? SSH Public Key /root/.ssh/id_rsa.pub
? Platform ovirt
? Engine FQDN[:PORT] rhvm.myhost.com:443
INFO Loaded the following PEM file:
INFO    Version: 3
INFO    Signature Algorithm: SHA256-RSA
INFO    Serial Number: 4096
INFO    Issuer: CN=rhvm.myhost.com.66464,O=myhost.com,C=US
INFO    Validity:
INFO            Not Before: 2020-12-16 15:04:02 +0000 UTC
INFO            Not After: 2030-12-15 15:04:02 +0000 UTC
INFO    Subject: CN=rhvm.myhost.com.66464,O=myhost.com,C=US
? Would you like to use the above certificate to connect to Engine?  Yes
? Engine username admin@internal
? Engine password [Press Ctrl+C to switch username, ? for help] ******
? Cluster Default
? Storage domain vms
? Network ovirtmgmt
? Internal API virtual IP 192.168.1.200
? Ingress virtual IP 192.168.1.201
? Base Domain myhost.com
? Cluster Name openshift01
? Pull Secret [? for help] *********


'
: '

##############################

cat >  /opt/OpenShift/install-config.yaml << EOF
apiVersion: v1
baseDomain: myhost.com
metadata:
  name: openshift01
platform:
  ovirt:
    api_vip: 192.168.1.200
    ingress_vip: 192.168.1.201
    ovirt_cluster_id: 7a714758-4079-11eb-92e0-00163e1396bd
    ovirt_storage_domain_id: e94c65b5-420f-4adf-9ff8-902617f7e0ef
    ovirt_network_name: ovirtmgmt
    vnicProfileID: 0000000a-000a-000a-000a-000000000398
pullSecret: "{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"registry.connect.redhat.com":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"},"registry.redhat.io":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"}}}"
sshKey: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKXkpTjpu0y4mQHOzWW1+grXIxcR9sIgEc0nR4WUOh6+YJL1bLfjrJMDWUmlLh5OZmcxVmTK5dBAkJqewAFqOx/WHFREP14he0/L0uujhnhtUqgP4xYC1BYXTZ1FGFAgpgWDFbQ7dIbUrvRca3ezdY2mKFYz2BkCeCCcxKiEq5PYnpbPxgTGHaIwfO8DFVlcVFR2g/OaWok1LeYm9ZidkWviMUJbILMJF9R3KUcOITz+zOp5+tXlGKA65jJH1R77CnQ3Ly3Tc6R4lhDfGV2RFx+kwCIwzq3lJoGFtk7WH81cnHICmSrW/IzAD8r6xnV8eGyyogLQG5Mw0KfJCvmKLrKaZXtF+HS7GDHOfI5RbnyzRW6q5sJ5dyUb+mtPlbixGE7gn5HWOF/L025sX5ddDnKXn2RstjE1jjhex7BZr9tFSIVwLLsWMJW5dSDF6Fb3yqPWWgMlUWxkdj5sTzV3xzVST6WK0kDbuK3t+03KVzRvkTEjfzl3CGd1AMX2nj0xNkDZuofxeEFj1IJTQqZWNI+8Ti4JlDX6nU05vUmSbEGfXrVkkJvcQLEutxJi+FvYJ85VAM+E5DAp2++jOMlELo3shI9t0oRWofj+VDA0gp2No7T+b9qAY5z/1uEzzMF+aSFR9yxY4swb5fNdHfCfn5UYjyxnbtBEqznu6iXazZ+w== root@helper.myhost.com"
EOF

time="2021-03-26T22:20:50+04:30" level=debug msg="Time elapsed per stage:"
time="2021-03-26T22:20:50+04:30" level=debug msg="    Infrastructure: 4m9s"
time="2021-03-26T22:20:50+04:30" level=debug msg="Bootstrap Complete: 22m58s"
time="2021-03-26T22:20:50+04:30" level=debug msg="               API: 1m20s"
time="2021-03-26T22:20:50+04:30" level=debug msg=" Bootstrap Destroy: 34s"
time="2021-03-26T22:20:50+04:30" level=debug msg=" Cluster Operators: 38m9s"
time="2021-03-26T22:20:50+04:30" level=info msg="Time elapsed: 1h6m2s"


INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/opt/OpenShift/auth/kubeconfig'
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.openshift01.myhost.com
INFO Login to the console with user: "kubeadmin", and password: "VPKEY-VnBpr-BENwL-uCVhM"
INFO Time elapsed: 1h6m2s
'

###################################################

htpasswd -c -b users.htpasswd hamid Iahoora@123
htpasswd -b users.htpasswd ali ahoora
htpasswd -b -B users.htpasswd developer developer

oc create secret generic localusers --from-file htpasswd=./users.htpasswd -n openshift-config

oc get oauth cluster -o yaml > oauth.yaml
vi oauth.yaml
########################
spec:
  identityProviders:
  - htpasswd:
      fileData:
        name: localusers
    mappingMethod: claim
    name: myusers
    type: HTPasswd
########################
oc replace -f oauth.yaml
oc get pods -n openshift-authentication

oc adm policy add-cluster-role-to-user cluster-admin hamid
oc extract secret/localusers -n openshift-config --to ./ext --confirm
oc set data secret/localusers --from-file ext/htpasswd -n openshift-config
oc delete secret localusers -n openshift-config
oc login
oc delete user --all
oc delete identity --all

###################################################
oc new-project authorization-secrets3
oc create secret generic mysql --from-literal user=myuser --from-literal password=redhat123 --from-literal database=test_secrets --from-literal hostname=mysql
oc new-app --name mysql --docker-image registry.access.redhat.com/rhscl/mysql-57-rhel7
oc set env deployment/mysql --from secret/mysql --prefix MYSQL_
oc set volume deployment/mysql --add --type secret --mount-path /run/secrets/mysql --secret-name mysql
oc new-app --name quotes --docker-image quay.io/redhattraining/famous-quotes:2.1
oc set env deployment/quotes --from secret/mysql --prefix QUOTES_
oc expose service/quotes
watch -n3 curl -s quotes-authorization-secrets3.apps.openshift01.myhost.com/status

##################################################

oc get pod  mysql-77cb576675-cdhj8 -o yaml | oc adm policy scc-subject-review -f -
oc create sa gitlab-sa
oc adm policy add-scc-to-user anyuuid -z gitlab-sa
oc set serviceaccount deployment/mysql gitlab-sa
##################################################


