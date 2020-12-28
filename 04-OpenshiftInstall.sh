curl ipinfo.io/country

IP1=192.168.1.200
IP2=192.168.1.201
IP3=192.168.1.202

WEBIP=192.168.1.111
IDMIP=192.168.1.112
SATIP=192.168.1.113


ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. api.openshift01 --a-rec 192.168.1.200 --a-create-reverse '
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add 1.168.192.in-addr.arpa. 200 --ptr-rec api.openshift01.myhost.com. '
ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. *.apps.openshift01 --a-rec 192.168.1.201 --a-create-reverse '
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add 1.168.192.in-addr.arpa. 201 --ptr-rec *.apps.openshift01.myhost.com. '

curl -k 'https://rhvm.myhost.com/ovirt-engine/services/pki-resource?resource=ca-certificate&format=X509-PEM-CA' -o /tmp/ca.pem
chmod 0644 /tmp/ca.pem
cp -p /tmp/ca.pem /etc/pki/ca-trust/source/anchors/rhvmca.pem
update-ca-trust

eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_rsa

mkdir Openshift
cd Openshift
cp /mnt/Mount/Files/OpenShift/openshift-install-linux.tar.gz ~/Openshift/
cp /mnt/Mount/Files/OpenShift/pull-secret.txt  ~/Openshift/
cp /mnt/Mount/Files/OpenShift/openshift-client-linux.tar.gz  ~/Openshift/

tar xvf openshift-install-linux.tar.gz
#ssh-keygen -t rsa -b 4096 -N '' -f ./OpenShift
eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_rsa
 
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
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"registry.connect.redhat.com":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"},"registry.redhat.io":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtrDqhO9/VZ0jjUdj/rrlt6YFsEdnxkZi9/84LgtRd6MU8O1Pvpj6I9uc5dgchGeN9Q6Y/+yg9QAAYXxxgdKqXLVVsGjl2rkbDLcf5Hv8eSoFLzEKM8mseD5ZgoMwiQ9PvFqxiEz85rFnWvXlHHBTGxcXmZKhPi7DxzLG3p/Q64MAFA6TRK0PPr/ixTyUhZ10sUF6M3JQ/ZaTPwrvWy5FzfvM8PN3lEnsWpxjHoUh5Q9VF5W2F4/aGtm1ZwH49ndTIwZnnLzrSjyl6zJ3xYxPoFQxiO4WCsbZN0KOg1FWhNuqrvXjrgKAxzme5AVbQr08b1iYUDyJozhfwQ/1V0dznXxcltENQifHxV8LHtz1XlemApRMy8lssPF9XfLHr6hUC8nOFQIwlFUJ8jyfHKP9I/9RZyPjNrwFCrA6T3IJmrs3j7CScNOoqjMDEXE/mybHHuzYEI1te0M5wuAT0q3j+fWNFiKo0Q5TG9JQBX+SiuT7IxEeKsDtp+PpqvFk/UyM= root@rhvh01.myhost.com'
EOF

./openshift-install create install-config --dir=/opt/OpenShift/
#./openshift-install create manifests --dir /opt/OpenShift/
./openshift-install create cluster --dir=/opt/OpenShift --log-level=info 

 ./openshift-install wait-for install-complete --dir=/opt/OpenShift --log-level=info
#./openshift-install destroy cluster --dir=/opt/OpenShift
#? SSH Public Key /root/.ssh/id_rsa.pub
#? Platform ovirt
#? Cluster Default
#? Storage domain hosted_storage
#? Network ovirtmgmt
#? Internal API virtual IP 192.168.1.200
#? Ingress virtual IP 192.168.1.201
#? Base Domain myhost.com
#? Cluster Name openshift01 ~/Openshift/pull-secret.txt
#INFO The file was found in cache: /root/.cache/openshift-installer/image_cache/bf57d087842dfffd400c0048c17dfd97. Reusing

#notes
#https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.6/
#https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.6/release.txt
