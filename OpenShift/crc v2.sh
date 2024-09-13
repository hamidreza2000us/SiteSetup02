#anaconda@123
#O0*vh}Ywv8Qlfz0z
#export XDG_RUNTIME_DIR="/run/user/0"
#export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
subscription-manager register --username=hamidreza2000us@yahoo.com --password=Iahoora@1234

user='crcuser'

activeCon=$( nmcli -m multiline -f name con sh --active | grep ens | awk -F: '{print $2}' | sed -e 's/^[ \t]*//')
nmcli con mod "$activeCon" ipv4.dns  127.0.0.1,1.1.1.1 
nmcli con reload
cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
nameserver 1.1.1.1
options edns0 trust-ad
EOF

cat << EOF > /tmp/crc.conf
server=/apps-crc.testing/192.168.130.11
server=/crc.testing/192.168.130.11
EOF

sudo mv /tmp/crc.conf /etc/NetworkManager/dnsmasq.d/crc.conf
systemctl restart NetworkManager


yum -y install wget git jq gettext
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

useradd -m ${user}
echo "ahoora" | passwd --stdin ${user}
echo "${user}   ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/10-${user}
#################
su - ${user}

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

#sudo snap install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
sudo cp /home/crcuser/kustomize /bin/

#wget https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/crc/2.2.0/crc-linux-amd64.tar.xz

wget https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/latest/crc-linux-amd64.tar.xz
tar xvf crc-linux-amd64.tar.xz 
mkdir -p ~/local/bin
mv crc-linux-*-amd64/crc ~/local/bin/
export PATH=$HOME/local/bin:$PATH
echo 'export PATH=$HOME/local/bin:$PATH' >> ~/.bashrc 

cat << EOF >> sec.txt
{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfNGQzOWJjYzAxMGI4NGQzYzkxODlkYzZmYTE1OGU3YjY6Vk1TUzBSUVhXNFM4MlE0SjlZQ1ZPU1g3WDFOVjVNRzhQRTk3TUZFMURNTTlVTDBKRE5FMVNORE1IQkJEVkxDTg==","email":"hr.moradi@futura-tec.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfNGQzOWJjYzAxMGI4NGQzYzkxODlkYzZmYTE1OGU3YjY6Vk1TUzBSUVhXNFM4MlE0SjlZQ1ZPU1g3WDFOVjVNRzhQRTk3TUZFMURNTTlVTDBKRE5FMVNORE1IQkJEVkxDTg==","email":"hr.moradi@futura-tec.com"},"registry.connect.redhat.com":{"auth":"fHVoYy1wb29sLTMzYjM2NWU1LTMwNTQtNGI5Ni1iMDFmLTQ5MzI3NWRlMjEyZjpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSTFNelk1TXpVMk5HVTVOek0wWWpFNVlUVTVOemMyTlRRek5UUXhOR1l5WmlKOS5MeG5SeEJnVWFxTFkyeXJ1UHBGSFU2LVNWc1pJWUkxaGc3ajU5V2JXTEEyd3Jzd3R3YWNtT2hYemhtU1Q1VnRCX1gxUkhEdGZidGJDSnNXaWtzcmlBdldVWi1zTUJlR1o3VnAwU1RFbXYxTHRnVmVoTjVpblExWW1ZNlNLSmJfZVdKeHV0VHFiNVpiN1liUWwxcktrQXVaLW9nYlZOcjZ0bEZZV1FaaFNSX3l5ZUhPVWYtV3F1bkFycjl4OU5MSXdxX0hIZHlKTXY0ZUhoMUNqSm1YcUozc2Yyc0tvVVBCdkRmUXZ6Vll5MXpoZVV6bUVCZ0thd2dGcGRoX0VvTDNaZjFBN2tUUXVfNEVZelE4QmJfWVB6QUdxd0syaG9Cczk4c3JYbXY3MGJKaF9sS29LX2M4SThldVJPN1VoNUZ5cW9NeXJhbVd2MDVQOFhCOHE3RTE3TEsyUFNTaF9ZcmdUOTIxNDZsdVJKLXdTamdic2JfZG5lSFpOMzcwb1YzUlNXWENrcVBjUmlQdU9vbDVDZkpMX1pWYjNMeHNVdnJpZnFaRHJjQ0UzaHBZNE5rOWpvc2MwaXlNdG1YNmc2XzlaNC1kY1dvNGJBLTI3aUMzc0VyZ1hqbXZTemR2QzdEeWFuTU12WnZjWEFXOFZJOElpUEI0V3lFc2wtc0xSem1WTnBUeFdveElrOHZST2QtWlFvTVZkaGw1VFNzRkJnZFUyS28yUE5IRi16anNRSVlMcS0yZkxBMFJJX1ZyVnd6NElDV3VxTTlYdS1PYzVHbngxZmtfNzhyUXNhNmFBenNPQXJDS180cktqN3hodndwX0hMenBURXRGcTBTbFlHTERwVlJZeFAwbEl1LXIzallGdUVGcjBwODY5bExmTks3MDhfZzZYNHhFbWNCSQ==","email":"hr.moradi@futura-tec.com"},"registry.redhat.io":{"auth":"fHVoYy1wb29sLTMzYjM2NWU1LTMwNTQtNGI5Ni1iMDFmLTQ5MzI3NWRlMjEyZjpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSTFNelk1TXpVMk5HVTVOek0wWWpFNVlUVTVOemMyTlRRek5UUXhOR1l5WmlKOS5MeG5SeEJnVWFxTFkyeXJ1UHBGSFU2LVNWc1pJWUkxaGc3ajU5V2JXTEEyd3Jzd3R3YWNtT2hYemhtU1Q1VnRCX1gxUkhEdGZidGJDSnNXaWtzcmlBdldVWi1zTUJlR1o3VnAwU1RFbXYxTHRnVmVoTjVpblExWW1ZNlNLSmJfZVdKeHV0VHFiNVpiN1liUWwxcktrQXVaLW9nYlZOcjZ0bEZZV1FaaFNSX3l5ZUhPVWYtV3F1bkFycjl4OU5MSXdxX0hIZHlKTXY0ZUhoMUNqSm1YcUozc2Yyc0tvVVBCdkRmUXZ6Vll5MXpoZVV6bUVCZ0thd2dGcGRoX0VvTDNaZjFBN2tUUXVfNEVZelE4QmJfWVB6QUdxd0syaG9Cczk4c3JYbXY3MGJKaF9sS29LX2M4SThldVJPN1VoNUZ5cW9NeXJhbVd2MDVQOFhCOHE3RTE3TEsyUFNTaF9ZcmdUOTIxNDZsdVJKLXdTamdic2JfZG5lSFpOMzcwb1YzUlNXWENrcVBjUmlQdU9vbDVDZkpMX1pWYjNMeHNVdnJpZnFaRHJjQ0UzaHBZNE5rOWpvc2MwaXlNdG1YNmc2XzlaNC1kY1dvNGJBLTI3aUMzc0VyZ1hqbXZTemR2QzdEeWFuTU12WnZjWEFXOFZJOElpUEI0V3lFc2wtc0xSem1WTnBUeFdveElrOHZST2QtWlFvTVZkaGw1VFNzRkJnZFUyS28yUE5IRi16anNRSVlMcS0yZkxBMFJJX1ZyVnd6NElDV3VxTTlYdS1PYzVHbngxZmtfNzhyUXNhNmFBenNPQXJDS180cktqN3hodndwX0hMenBURXRGcTBTbFlHTERwVlJZeFAwbEl1LXIzallGdUVGcjBwODY5bExmTks3MDhfZzZYNHhFbWNCSQ==","email":"hr.moradi@futura-tec.com"}}}
EOF
crc config set skip-check-daemon-systemd-unit true
crc config set skip-check-daemon-systemd-sockets true
crc config set consent-telemetry no

crc config set cpus 15
crc config set disable-update-check true
crc config set disk-size 360
crc config set memory 20480
#crc config set nameserver 1.1.1.1
crc config set pull-secret-file ~/sec.txt
crc config set kubeadmin-password ahoora
crc config set disable-update-check true
crc config view

#sudo virsh list --all
#sudo virsh destroy crc
#sudo virsh undefine crc

# crc delete -f
# crc cleanup
# crc setup
# crc start --log-level debug
#sudo chown crcuser:crcuser /home/crcuser/.crc/cache/crc_libvirt_4.16.4_amd64/crc.qcow2

time crc setup
time crc start --log-level debug
#time crc start -c 16 -d 110 -m 20480 -p sec.txt

#for host in /sys/class/scsi_host/*; do echo "- - -" | sudo tee $host/scan; ls /dev/sd* ; done

sudo dnf -y install haproxy /usr/sbin/semanage firewalld bash-completion git
sudo systemctl enable --now firewalld;
sudo firewall-cmd --add-service=http --permanent;
sudo firewall-cmd --add-service=https --permanent;
sudo firewall-cmd --add-service=kube-apiserver --permanent;
sudo firewall-cmd --reload;
sudo semanage port -a -t http_port_t -p tcp 6443
sudo cp /etc/haproxy/haproxy.cfg{,.bak}
export CRC_IP=$(crc ip)
sudo tee /etc/haproxy/haproxy.cfg &>/dev/null <<EOF
global
    log /dev/log local0

defaults
    balance roundrobin
    log global
    maxconn 100
    mode tcp
    timeout connect 5s
    timeout client 500s
    timeout server 500s

listen apps
    bind 0.0.0.0:80
    server crcvm $CRC_IP:80 check

listen apps_ssl
    bind 0.0.0.0:443
    server crcvm $CRC_IP:443 check

listen api
    bind 0.0.0.0:6443
    server crcvm $CRC_IP:6443 check
EOF

sudo systemctl enable haproxy
sudo systemctl restart haproxy
sudo systemctl status haproxy

eval $(crc oc-env) ;
oc completion bash > /tmp/oc.sh ;
chmod +x /tmp/oc.sh ;
crc completion bash > /tmp/crc.sh ;
chmod +x /tmp/crc.sh ;

sudo mv /tmp/oc.sh /etc/bash_completion.d/ ;
sudo mv /tmp/crc.sh /etc/bash_completion.d/ ;

echo 'source /etc/bash_completion.d/oc.sh' >> ~/.bashrc ;
echo 'source /etc/bash_completion.d/crc.sh' >> ~/.bashrc ;
echo 'eval $(crc oc-env)' >> ~/.bashrc ;
echo 'oc login -u kubeadmin -p ahoora' >> ~/.bashrc ;

source /etc/bash_completion.d/oc.sh ;
source /etc/bash_completion.d/crc.sh ;

#dnf copr -y enable chmouel/tektoncd-cli
#dnf install -y tektoncd-cli

#####login

oc new-project cicd
#while read line ; do oc delete pod/$line ; done< <(oc get pods | grep openshift-workshops-git2 | awk '{print $1}')

helm repo add redhat-cop https://redhat-cop.github.io/helm-charts
helm upgrade --install argocd redhat-cop/gitops-operator --set namespaces[0]=cicd --create-namespace --namespace cicd
helm upgrade --install sonar redhat-cop/sonarqube -n cicd
helm upgrade --install nexus redhat-cop/sonatype-nexus -n cicd
#helm upgrade --install ipa redhat-cop/ipa -n cicd #Passw0rd123
#ldapsearch -x -LLL

cluster=apps-crc.testing
helm upgrade --install --repo=https://redhat-cop.github.io/helm-charts gitea gitea --set db.password=openshift --set hostname=gitea-cicd.$cluster -n cicd
#./gitea -c /home/gitea/conf/app.ini admin user create --username hamid --password admin123 --email hamidrezamoradi@gmail.com --admin

oc project cicd
git clone https://github.com/ricardoaraujo75/devops-ocp-helm.git
oc apply -f devops-ocp-helm/templates/operator-pipeline/openshift-pipelines-sub.yaml


# git config --global http.sslCAInfo ~/git-certs/cert.pem
# git config --global --list
git config --global http.sslVerify false
#host="gitea-cicd.apps-crc.testing" ; openssl s_client -showcerts -connect $host:443 -servername $host  </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -inform PEM  -outform DER -out /etc/pki/ca-trust/source/anchors/$host.cer
#  host="gitea-cicd.apps-crc.testing" ; openssl s_client -showcerts -connect $host:443 -servername $host  </dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /etc/pki/ca-trust/source/anchors/$host.pem; sudo chmod 644 /etc/pki/ca-trust/source/anchors/$host.cer ; sudo update-ca-trust extract ; curl $host


oc project cicd
cluster=apps-crc.testing
helm --set pipeline.gitea.host=gitea-cicd.$cluster --set cluster=$cluster template -f devops-ocp-helm/values.yaml devops-ocp-helm  | oc apply -f-
oc policy add-role-to-user edit system:serviceaccount:cicd:pipeline -n dev
oc policy add-role-to-user edit system:serviceaccount:cicd:pipeline -n sta
oc policy add-role-to-user edit system:serviceaccount:cicd:pipeline -n prod

#https://github.com/ricardoaraujo75/devops-ocp-app.git
git clone https://github.com/ricardoaraujo75/devops-ocp-app.git



#################################
set -x; cd "$(mktemp -d)" &&   OS="$(uname | tr '[:upper:]' '[:lower:]')" &&   ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&   KREW="krew-${OS}_${ARCH}" &&   curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&   tar zxvf "${KREW}.tar.gz" &&   ./"${KREW}" install krew
set +x
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
oc krew update
oc krew search
#################################

#git clone https://github.com/coolstore-demo/coolstore.git

git config --global user.email 'hamidreza2000us@yahoo.com'
git config --global user.name 'hamidreza'
mkdir cool01
cd cool01
git clone https://github.com/hamidreza2000us/coolstore.git
cd coolstore/

find . -type f -exec sed -i 's|\${SUB_DOMAIN}|apps-crc.testing|g' {} +
find . -type f -exec sed -i 's|github.com/coolstore-demo|github.com/hamidreza2000us|g' {} +
find . -type f -exec sed -i 's|github.com/redhat-cop/gitops-catalog|github.com/redhat-cop/gitops-catalog/tree/main|g' {} +
find . -type f -exec sed -i '/\/tree\/main/ { s|/tree/main|/|; s|$|?ref=main| }' {} +

sed -i 's|channel: gitops-1.9|channel: latest|' infra/components/gitops-operator/operator/base/subscription.yaml
sed -i 's|gitops-operator-controller-manager|openshift-gitops-operator-controller-manager|' bootstrap.sh
sed -i '/extraSourceFields:/,/name: kustomize-envvar/d'  clusters/default/infra/argo/base/values.yaml
sed -i '/extraSourceFields:/,/name: kustomize-envvar/d'  clusters/default/demo/argo/base/values.yaml
sed -i '/plugin:/,/name: kustomize-envvar/d'  bootstrap/argo/base/bootstrap.yaml
sed -i '/configManagementPlugins:/,/args:/d' infra/components/gitops-operator/instance/base/argocd-cr.yaml

git add .
git commit -m 'rewrite git url '
git remote set-url origin 
git push origin main

bash bootstrap.sh 

oc get secret -n openshift-gitops openshift-gitops-cluster -o json | jq -r '.data["admin.password"]' | base64 -d

oc rsh -n openshift-authentication   $(oc get pods -n openshift-authentication | grep oauth-openshift | awk '{print $1}')  cat /run/secrets/kubernetes.io/serviceaccount/ca.crt | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | awk 'n==4; /-----END CERTIFICATE-----/{n++}' > oc-ca.crt
#oc rsh -n openshift-authentication   $(oc get pods -n openshift-authentication | grep oauth-openshift | awk '{print $1}')  cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > oc-ca.crt
#oc create cm argocd-tls-certs-cm  --namespace openshift-gitops --tls-server-name gitea-gitea.apps-crc.testing --from-file oc-ca.crt
sudo cp oc-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
cat oc-ca.crt

#take 12 min to load gitea, if failed:
oc delete job -n gitea configure-gitea

# while read line ; do oc -n openshift-gitops delete app $line ; done< <(oc get app -A | grep -vE "NAME|Synced|bootstrap" | awk '{print $2}')
#find . -type f -exec grep -oP 'github.com/[^ ]+' {} + | sort -u | xargs -I {} sh -c 'echo -n "{}: "; curl -o /dev/null -s -w "%{http_code}\n" "https://{}"'


repo: https://github.com/coolstore-demo/gateway-vertx.git