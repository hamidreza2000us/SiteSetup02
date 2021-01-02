curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz
tar xvf openshift-client-linux.tar.gz
mv oc /usr/local/bin/

mkdir Openshift
cd Openshift

curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/pull-secret.txt -o pull-secret.txt
scp  -o StrictHostKeyChecking=no  ${QuayIP}:/root/rootCA.pem /etc/pki/ca-trust/source/anchors/quay.ca
update-ca-trust
export LOCAL_SECRET_JSON='pull-secret.txt'
export REMOVABLE_MEDIA_PATH=/repos
export PRODUCT_REPO='openshift-release-dev'
export RELEASE_NAME="ocp-release"
export OCP_RELEASE=4.6.8
export ARCHITECTURE=x86_64
export LOCAL_REGISTRY='quay.myhost.com'
export LOCAL_REPOSITORY='ocp468/testrepo'
oc adm release extract -a ${LOCAL_SECRET_JSON} --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}"
mv openshift-install /usr/local/bin/


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
  none: {} 
fips: false
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

openshift-install create manifests --dir=/opt/OpenShift
#modify some files here
openshift-install create ignition-configs --dir=/opt/OpenShift
