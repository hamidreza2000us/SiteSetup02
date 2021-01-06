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

scp  -o StrictHostKeyChecking=no  ${QuayIP}:/root/rootCA.pem /etc/pki/ca-trust/source/anchors/quay.ca
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
scp -o StrictHostKeyChecking=no  rhvh01.myhost.com:/mnt/Mount/Files/OpenShift/bf57d087842dfffd400c0048c17dfd97 /root/.cache/openshift-installer/image_cache/

##################################
mkdir /root/.ovirt
cat > /root/.ovirt/ovirt-config.yaml << EOF
ovirt_url: https://rhvm.myhost.com:443/ovirt-engine/api
ovirt_fqdn: rhvm.myhost.com:443
ovirt_pem_url: https://rhvm.myhost.com:443/ovirt-engine/services/pki-resource?resource=ca-certificate&format=X509-PEM-CA
ovirt_username: admin@internal
ovirt_password: ahoora
ovirt_ca_bundle: |-
  -----BEGIN CERTIFICATE-----
  MIIDsTCCApmgAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwQjELMAkGA1UEBhMCVVMxEzARBgNVBAoM
  Cm15aG9zdC5jb20xHjAcBgNVBAMMFXJodm0ubXlob3N0LmNvbS42NjQ2NDAeFw0yMDEyMTYxNTA0
  MDJaFw0zMDEyMTUxNTA0MDJaMEIxCzAJBgNVBAYTAlVTMRMwEQYDVQQKDApteWhvc3QuY29tMR4w
  HAYDVQQDDBVyaHZtLm15aG9zdC5jb20uNjY0NjQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
  AoIBAQDZp63Sgv8740OVSF7iGryEbfTbYWGG7zkuHg5J02wQmp/Y8JxTiMFLqX2tap/KmIp2YO8e
  6Xen5Pt2KWKTZqzPyJMWg6sL+WIi6FHCkJ3MILf3BaGGtGB4oK3spvTs7LU3u7KzJfm4HxwUePqY
  2TBtvaAlPg9V9hHwblpYrW5Xp52ZPO07vdBM+0WPwMkFvve7su0gu17HwoMmI7orQqAuvmPEO4Bv
  u3x82XyO6HjUd1TYIl7dTdggoJf3yszolu1Rh4NKFe0bParTG4ijfWnUQDbcuzuPOw4KVvobCRk/
  Vm/ubvd+hChV4gEeqiLxldoupoKWbr0VCEcYn5KgKg41AgMBAAGjgbAwga0wHQYDVR0OBBYEFIqU
  Wlqs9bTd/i9EChwFadQhD8xRMGsGA1UdIwRkMGKAFIqUWlqs9bTd/i9EChwFadQhD8xRoUakRDBC
  MQswCQYDVQQGEwJVUzETMBEGA1UECgwKbXlob3N0LmNvbTEeMBwGA1UEAwwVcmh2bS5teWhvc3Qu
  Y29tLjY2NDY0ggIQADAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjANBgkqhkiG9w0B
  AQsFAAOCAQEAEEALCgRTQEmTYp3/UL1fhausZsm7GVJ4I7/YMuEEBjr0JYu9+c4z/FpTkw5A0VJi
  EjOYqehiYfY+ahaDIi6iv8zZgdY53IwuCxVnfj/Y0J+2FD0cX7EhvKypmbQcFwJE8atFj3BkhQKV
  4JMP1R999YLu9pF2/C0PqxxrnLwmOP/wd7Fb2JMUicU0FXIQ0Z/r6SP3BPIz1KwX1TFWz/a/I35x
  rM+8P3L/wemt/n3JQnxXBKzAajNh1EZXnv3+tp+MAdOC5Z5Md7r5geZTvrDz4Z5F1O9NIQ4K8RGc
  46UCbYQ4mgRdgQi8tEiZ+/kZqfEbFfILBssz1eCqLIFgJ9JtGg==
  -----END CERTIFICATE-----
EOF
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
  replicas: 2
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
    ovirt_storage_domain_id: 04e1dad3-bb9c-4ee9-8977-ccf922f23cb2
    vnicProfileID: 0000000a-000a-000a-000a-000000000398
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"registry.connect.redhat.com":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"},"registry.redhat.io":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"}}}'
sshKey: ${PUBKEY}
publish: External
additionalTrustBundle: | 
  -----BEGIN CERTIFICATE-----
  MIIDqTCCApGgAwIBAgIUSR3Qf5vKr3ZcGZgDFTQxqn7iPAYwDQYJKoZIhvcNAQEL
  BQAwZDELMAkGA1UEBhMCR1IxEjAQBgNVBAgMCUZyYW5rZnVydDESMBAGA1UEBwwJ
  RnJhbmtmdXJ0MRMwEQYDVQQKDApTYW5DbHVzdGVyMRgwFgYDVQQDDA9xdWF5Lm15
  aG9zdC5jb20wHhcNMjAxMjI3MDQwNTQxWhcNMjMxMDE3MDQwNTQxWjBkMQswCQYD
  VQQGEwJHUjESMBAGA1UECAwJRnJhbmtmdXJ0MRIwEAYDVQQHDAlGcmFua2Z1cnQx
  EzARBgNVBAoMClNhbkNsdXN0ZXIxGDAWBgNVBAMMD3F1YXkubXlob3N0LmNvbTCC
  ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOfirYJjYBNI2Si/XkvPlXgb
  LzXc6AwAah0RLNqIx2k2jWnWa2JPFhvX9KCm1ytNDas+f382XQLRXhBz0MvIUKr7
  u3G++z3ycD4YAYovCktbMgHzBIsnsBbhk5qP13VbaaLWHQn3+Bk7GcsTPKZxNcDV
  aY0kxnGQVhixS1PXVAK2so+ckhdRaiMsLPIp3w7nPbvMHgrPGWstYGxyLnw0r9VI
  9POlmNeTpICC0s/T0Ix3ythTxV4OS+yC5hsrT2cZZ5vFnsQ0bYOUi9JjMfffFNcL
  zL8Vfu0fcYc+orAgHuUHHFYIPI0lnmziyT83mfTO29N1A8zVkt2w30Y19K44PYMC
  AwEAAaNTMFEwHQYDVR0OBBYEFPM+43Vp1Q6TTMUAxNfIIBptgN3wMB8GA1UdIwQY
  MBaAFPM+43Vp1Q6TTMUAxNfIIBptgN3wMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZI
  hvcNAQELBQADggEBABFUgrWywuKg/yaSslTZ3NmmeMYGbbBLFbCtIYYyfwUDiJLf
  VrgireCxZSzrMvtRJnMDTgCtCgKQYKpD5zLZatZKOZhriri6HgJHMnokQ9wE8rj/
  xW9HqcVVHnouVY4P8RZiidBr6oquWZZeOgxE77+RNuLUCo1p/7FVP+ylau69C0W5
  cWwd6Ma6MDj5NDq4EYThZ4VL91kIni1jIbbEE9aQdhGhFjg7F571COGeKbld3eXD
  RDEiCpiyGqDn7eEofYFPWf7oi97RolWxd9lvyfZaDeOY7NRmvel7oMG+KYF1yuzW
  zKk5ZHOX8irpc7c/kBhOpO6XV25nOb9usJAn0Vs=
  -----END CERTIFICATE-----
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
openshift-install create cluster --dir=/opt/OpenShift --log-level=info

#openshift-install wait-for bootstrap-complete --dir=/opt/OpenShift --log-level=debug
#openshift-install wait-for install-complete --dir=/opt/OpenShift --log-level=debug
#openshift-install destroy cluster --dir=/opt/OpenShift

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

INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/opt/OpenShift/auth/kubeconfig'
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.openshift01.myhost.com
INFO Login to the console with user: "kubeadmin", and password: "ccVBD-XeEQA-hdcK2-aNSyT"
DEBUG Time elapsed per stage:
DEBUG Cluster Operators: 14m0s
INFO Time elapsed: 14m0s

'