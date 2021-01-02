#https://docs.openshift.com/container-platform/4.6/installing/installing_bare_metal_ipi/ipi-install-installation-workflow.html
#install RH8.1 with two interfaces
IDMIP=192.168.1.112
ProvisionerIP=192.168.1.134

cd /mnt/Mount/Yaml
ansible-playbook -i ~/.inventory create-vmFromTemplateWIP.yml -e VMName=Provisioner -e VMMemory=16GiB -e VMCore=6  \
-e HostName=ProvisionerIP.myhost.com -e VMTempate=Template8.3 -e VMISO=rhel-8.3-x86_64-dvd.iso -e VMIP=${ProvisionerIP}

sed -i "/${ProvisionerIP}/d" /root/.ssh/known_hosts
#ssh -o StrictHostKeyChecking=no ${IDMIP} 'echo "Iahoora@123" | kinit admin; ipa dnsrecord-add myhost.com. Provisioner --a-ip-address=192.168.1.134  --a-create-reverse '

ssh -o StrictHostKeyChecking=no ${ProvisionerIP} 'useradd kni'
ssh -o StrictHostKeyChecking=no ${ProvisionerIP} 'echo "ahoora" | passwd kni --stdin'
ssh -o StrictHostKeyChecking=no ${ProvisionerIP} 'echo "kni ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/kni'
ssh -o StrictHostKeyChecking=no ${ProvisionerIP} 'chmod 0440 /etc/sudoers.d/kni'
ssh -o StrictHostKeyChecking=no ${ProvisionerIP} /bin/bash << 'EOF'
su - kni -c "ssh-keygen -t rsa -f /home/kni/.ssh/id_rsa -N ''"
EOF
sshpass -p "ahoora" ssh-copy-id -i ~/.ssh/id_rsa.pub kni@${ProvisionerIP}
ssh kni@${ProvisionerIP} sudo mount -o ro,loop /dev/cdrom /mnt/cdrom
ssh kni@${ProvisionerIP} sudo dnf install -y libvirt qemu-kvm mkisofs python3-devel jq ipmitool firewalld

ssh kni@${ProvisionerIP} sudo usermod --append --groups libvirt kni

ssh kni@${ProvisionerIP} sudo systemctl start firewalld
ssh kni@${ProvisionerIP} sudo firewall-cmd --zone=public --add-service=http --permanent
ssh kni@${ProvisionerIP} sudo firewall-cmd --reload

ssh kni@${ProvisionerIP} 'sudo systemctl start libvirtd'
ssh kni@${ProvisionerIP} 'sudo systemctl enable libvirtd --now'

ssh kni@${ProvisionerIP} sudo virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images
ssh kni@${ProvisionerIP} sudo virsh pool-start default
ssh kni@${ProvisionerIP} sudo virsh pool-autostart default
##################
sudo ip r a default via 192.168.1.155
sudo ip r d default via 192.168.1.1 dev eth0
curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/pull-secret.txt -o pull-secret.txt
curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/openshift-install-linux.tar.gz -o openshift-install-linux.tar.gz 
curl http://rhvh01.myhost.com/RHEL/Files/OpenShift/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz
tar xvf openshift-client-linux.tar.gz
export VERSION=latest-4.6
export RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}')
#scp /mnt/Mount/Files/OpenShift/openshift-install kni@${ProvisionerIP}:~/
#scp /mnt/Mount/Files/OpenShift/openshift-client-linux.tar.gz kni@${ProvisionerIP}:~/
export cmd=openshift-baremetal-install
export pullsecret_file=~/pull-secret.txt
export extract_dir=$(pwd)
#curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/openshift-client-linux-$VERSION.tar.gz | tar zxvf - oc
sudo cp oc /usr/local/bin
#oc adm release extract --registry-config "${pullsecret_file}" --command=$cmd --to "${extract_dir}" ${RELEASE_IMAGE}
#sudo cp openshift-baremetal-install /usr/local/bin
sudo cp openshift-install /usr/local/bin/openshift-baremetal-install
sudo dnf install -y podman
sudo firewall-cmd --add-port=8080/tcp --zone=public --permanent
mkdir /home/kni/rhcos_image_cache
sudo semanage fcontext -a -t httpd_sys_content_t "/home/kni/rhcos_image_cache(/.*)?"
sudo restorecon -Rv rhcos_image_cache/
#export COMMIT_ID=$(/usr/local/bin/openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
#export RHCOS_OPENSTACK_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq .images.openstack.path | sed 's/"//g')
#export RHCOS_QEMU_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq .images.qemu.path | sed 's/"//g')
#export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')
#export RHCOS_QEMU_SHA_UNCOMPRESSED=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq -r '.images.qemu["uncompressed-sha256"]')
#export RHCOS_OPENSTACK_SHA_COMPRESSED=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq -r '.images.openstack.sha256')
#curl -L ${RHCOS_PATH}${RHCOS_QEMU_URI} -o /home/kni/rhcos_image_cache
#curl -L ${RHCOS_PATH}${RHCOS_OPENSTACK_URI} -o /home/kni/rhcos_image_cache
scp /mnt/Mount/Files/OpenShift/rhcos-46.82.202011260640-0-qemu.x86_64.qcow2.gz  kni@${ProvisionerIP}:~/rhcos_image_cache
sudo restorecon -Rv rhcos_image_cache/
scp /mnt/Mount/Files/OpenShift/httpd-24-centos7.tar  kni@${ProvisionerIP}:~/rhcos_image_cache
podman load -i ~/rhcos_image_cache/httpd-24-centos7.tar
podman run -d --name rhcos_image_cache \
-v /home/kni/rhcos_image_cache:/var/www/html \
-p 8080:8080/tcp \
registry.centos.org/centos/httpd-24-centos7:latest

mkdir ~/clusterconfigs
cat >  ~/clusterconfigs/install-config.yaml << EOF
apiVersion: v1
baseDomain: myhost.com
metadata:
  name: openshift01
platform:
  ovirt:
    api_vip: 192.168.1.200
    ingress_vip: 192.168.1.201
    ovirt_cluster_id: 7a714758-4079-11eb-92e0-00163e1396bd
    ovirt_storage_domain_id: d1c17b17-a096-422e-862a-71f14ea62748
    ovirt_network_name: ovirtmgmt
    vnicProfileID: 0000000a-000a-000a-000a-000000000398
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2hybW9yYWRpaHBjbWljcm9zeXN0ZW1zbmV0MWQxenNxb213cHo4NW1scmZma2VlaGV3cmF4OjBSRUNZMlM5SlNPM1FEREFSNEpQSUlFNU1EUDVOUlpDSk5KWjBOUTc0NlQ1TkRKSUNTRjZWVFZBVzdCSE1TT0M=","email":"hr.moradi@hpcmicrosystems.net"},"registry.connect.redhat.com":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"},"registry.redhat.io":{"auth":"NTMyNTE2MDR8dWhjLTFkMXpzcW9td1BaODVtbHJGZktFZUhld1JBWDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSm1PRGN5TVRJd1ptTXhNVGcwWkRVeVltSXpNbUpqWTJRME0yWXdZekJpTkNKOS5VQy16aHBXWWR2NExnWXdQOEJHWkZtOFB6SEFxX1RndUJJMHZFR2hnMnpRMUF3cGFVeE82VzhlX0NKVlEtbGk3a0ZUSVpESnMzZGFmRGxva0I2YmlwZGtNbEZENm16Mnd2ZzdZRHJadnFuYk1RSFpMbm1qYlhLNzdlVll5ZkNqMDZLRlNoWm83MUFBNE5OX1FUQVpTWnk0OFdJejhJWHN2ckdxdDhJSHlWRVNwb3VJSXdzc0dZTm85LXgtRktOQVpVamk0TF8tWi1GTzBFQWJNT0x0NDQtM2dabU40YUZ6eWh5TGZyUWdJQlhSZWJORkREMTlmUENGX2xzZTNDM3JxM3lFZldWalM2V0pESy1samRaY3h3MGR2STV0WjJ3N2VVUm9kQ19JNS1NR3U5akJYSjhqTEF3Ujg4eXVkMlpJMDdxU3lrMEtEV1F6Ti1yMjFMUDlZUlJzNTlEM2wwSjFyekpJMWRKRXl2NmstRmNBaEdJdTlLUktLLWw0LTIySW1DcWJHMlNLUjBOMDNNMFRHVmtoX3g0bTk5M043dG5JSEVVeEQ1QTl6S1lDY0VmdlhmbFlJU3E0bVlBUS0yQlRqRnFzSmhOb0psZG00OHJSVzg2RHQ0ME9BMUVVXzB5VUwtRnVYQ3hkZUc5OGIxQlRpUWVpal9SU3VYWmJiOUZqUGhCaHVpSlpLNE05eUZDenZKZ0pmVlFJRklvZzVTTW9JVHJEZnBzb3NVaGFiTnBSU2sxLWFSOEczZ1V0TWZvajdUbW44UUh0UEdLOFB0Qm1kUHRJdlAtc0Z6cE5MdDlYT1B5elhQY0VvV3h0WllOV1pNc1AzTmt4bWdpNHpiYXNBNU5vaFZUN01jNm5JU1NVTUZzTTM4c2MyVnVQUkk5UVFtb3hfTVRSeEt6cw==","email":"hr.moradi@hpcmicrosystems.net"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvOXsgJbJ7K+A6ORlx1TkXLPHvgntHAViTkzFF2sQ+0h81c0jqMlty7dLlURUiZl0ymQMSGsxt3KtQy0ae2JDdk0CgNb67S8vlIdH9hXLbr9OWNXsjMWljqYHg21NEeYVw0UPbqsfzkS1nKyHOJgvCyFlRLaNddnP7KY1NgkhK2QSGIGyZEbCdNA2PuOGuryVwA34Jh9gWik6njXjJfbQCRYv0VsyhY2UXJg2JcrnzvhtbrTuJNoonDY7vjeAMkulLxdihFcNRDx9MDVL/0Gwwgfugxb5K1qyjIY7JPEc9FPR13CTASTmllIbyo9/6GANeb7I6gAfkLZ7vuWFRQPTLTnNIacUQnZ0I4gxvPmMFlOXR6BEraGOHBYJ+4Erfh2XlWwkrFYfkHpZt6HXB4AjUlo3RVrGPxv/IbMKOEqppnemtXh/IkRl02l8SXAUuLAXPZlEcR3N4PFZoHs5nKIGBcJiji5N7gy6EUk5HI/XY6tbTo2JyMhbAb2wdDDK2Iv0= kni@ProvisionerIP.myhost.com'
EOF

#ipmitool -I lanplus -U <user> -P <password> -H <management-server-ip> power off
for i in $(sudo virsh list | tail -n +3 | grep bootstrap | awk {'print $2'});
do
  sudo virsh destroy $i;
  sudo virsh undefine $i;
  sudo virsh vol-delete $i --pool default;
  sudo virsh vol-delete $i.ign --pool default;
done

#./openshift-baremetal-install --dir ~/clusterconfigs create manifests
./openshift-install create install-config --dir=~/clusterconfigs

#####################################################
sudo firewall-cmd --add-port=5000/tcp --zone=libvirt  --permanent
sudo firewall-cmd --add-port=5000/tcp --zone=public   --permanent
sudo firewall-cmd --reload

sudo yum -y install python3 podman httpd httpd-tools jq
sudo mkdir -p /opt/registry/{auth,certs,data}

host_fqdn=$( hostname --long )
cert_c="US"   # Country Name (C, 2 letter code)
cert_s="WA"          # Certificate State (S)
cert_l="Seattle"       # Certificate Locality (L)
cert_o="Sancluster"   # Certificate Organization (O)
cert_ou="IT"      # Certificate Organizational Unit (OU)
cert_cn="${host_fqdn}"    # Certificate Common Name (CN)

sudo openssl req \
    -newkey rsa:4096 \
    -nodes \
    -sha256 \
    -keyout /opt/registry/certs/domain.key \
    -x509 \
    -days 365 \
    -out /opt/registry/certs/domain.crt \
    -subj "/C=${cert_c}/ST=${cert_s}/L=${cert_l}/O=${cert_o}/OU=${cert_ou}/CN=${cert_cn}"
	
sudo cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust extract

htpasswd -bBc /opt/registry/auth/htpasswd admin ahoora

#seems buggy due to download
scp /mnt/Mount/Files/OpenShift/registry.tar  kni@${ProvisionerIP}:~/rhcos_image_cache
podman load -i ~/rhcos_image_cache/registry.tar
podman create \
  --name ocpdiscon-registry \
  -p 5000:5000 \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
  -e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  -e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt" \
  -e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key" \
  -e "REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true" \
  -v /opt/registry/data:/var/lib/registry:z \
  -v /opt/registry/auth:/auth:z \
  -v /opt/registry/certs:/certs:z \
  docker.io/library/registry:2

podman start ocpdiscon-registry

#scp kni@provisioner:/home/kni/pull-secret.txt pull-secret.txt
host_fqdn=$( hostname --long )
b64auth=$( echo -n 'admin:ahoora' | openssl base64 )
AUTHSTRING="{\"$host_fqdn:5000\": {\"auth\": \"$b64auth\",\"email\": \"$USER@redhat.com\"}}"
jq ".auths += $AUTHSTRING" < pull-secret.txt > pull-secret-update.txt


b64auth=$( echo -n 'hamid:Iahoora@123' | openssl base64 )
AUTHSTRING="{\"quay.myhost.com\": {\"auth\": \"$b64auth\",\"email\": \"$USER@redhat.com\"}}"
jq ".auths += $AUTHSTRING" < pull-secret.txt > pull-secret-update.json

sshpass -p ahoora  scp -o StrictHostKeyChecking=no   root@quay.myhost.com:/etc/docker/certs.d/quay.myhost.com/ca.crt /tmp/quayca.crt
sshpass -p ahoora  scp -o StrictHostKeyChecking=no  /tmp/quayca.crt  root@${ProvisionerIP}:/etc/pki/ca-trust/source/anchors/quayca.crt
ssh kni@${ProvisionerIP} sudo update-ca-trust

#######################temp#####################
oc adm release mirror -a ${LOCAL_SECRET_JSON} --to-dir=${REMOVABLE_MEDIA_PATH}/mirror quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}
oc image mirror  -a ${LOCAL_SECRET_JSON} --from-dir=${REMOVABLE_MEDIA_PATH}/mirror "file://openshift/release:${OCP_RELEASE}*" ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} 

export LOCAL_SECRET_JSON='/home/kni/pull-secret-update.json'
export REMOVABLE_MEDIA_PATH=/repos
export PRODUCT_REPO='openshift-release-dev'
export RELEASE_NAME="ocp-release"
export OCP_RELEASE=4.6.9
export ARCHITECTURE=x86_64
export LOCAL_REGISTRY='quay.myhost.com'
export LOCAL_REPOSITORY='ocp468/testrepo'

oc adm release mirror -a ${LOCAL_SECRET_JSON}  \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run
	 
oc adm release mirror -a ${LOCAL_SECRET_JSON} --to-dir=${REMOVABLE_MEDIA_PATH}/mirror quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}


oc image mirror  -a ${LOCAL_SECRET_JSON} --from-dir=${REMOVABLE_MEDIA_PATH}/mirror "file://openshift/release:${OCP_RELEASE}*" ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}

oc adm release extract -a ${LOCAL_SECRET_JSON} --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"
##############################################
cat >> install-config.yaml << EOF
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


#######################
sudo nmcli connection add ifname provisioning type bridge con-name provisioning
sudo nmcli con add type bridge-slave ifname eth0 master provisioning
sudo nmcli connection modify provisioning ipv6.addresses fd00:1101::1/64 ipv6.method manual
sudo nmcli con del System\ eth0

ssh -o StrictHostKeyChecking=no kni@${ProvisionerIP} /bin/bash << 'EOF'
export PUB_CONN="System eth0"
export PROV_CONN="Wired connection 1"
sudo nohup bash -c "
    nmcli con down \"$PROV_CONN\"
    nmcli con down \"$PUB_CONN\"
    nmcli con delete \"$PROV_CONN\"
    nmcli con delete \"$PUB_CONN\"
    # RHEL 8.1 appends the word \"System\" in front of the connection, delete in case it exists
    nmcli con down \"System $PUB_CONN\"
    nmcli con delete \"System $PUB_CONN\"
    nmcli connection add ifname provisioning type bridge con-name provisioning
    nmcli con add type bridge-slave ifname \"$PROV_CONN\" master provisioning
    nmcli connection add ifname baremetal type bridge con-name baremetal
    nmcli con add type bridge-slave ifname \"$PUB_CONN\" master baremetal
    pkill dhclient;dhclient baremetal
    nmcli connection modify provisioning ipv6.addresses fd00:1101::1/64 ipv6.method manual
    nmcli con down provisioning
    nmcli con up provisioning
"
EOF
