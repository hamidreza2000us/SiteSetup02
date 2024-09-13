sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
#reboot

subscription-manager unregister
yum clean all
subscription-manager register --org="MCI" --activationkey="KCent7" --force
yum install --nogpgcheck -y kubectl
yum install -y minikube  conntrack

#yum install -y  docker 
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc
#subscription-manager unregister
#cat > /etc/yum.repos.d/docker-ce.repo << 'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=http://download.docker.com/linux/centos/$releasever/$basearch/stable
enabled=1
gpgcheck=0
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
#yum-config-manager     --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io

yum -y install docker
sed -i '/^ExecStart=.*/i Environment="HTTP_PROXY=http://172.16.49.98:80"' /usr/lib/systemd/system/docker.service
sed -i '/^ExecStart=.*/i Environment="HTTPS_PROXY=http://172.16.49.98:80"' /usr/lib/systemd/system/docker.service
sed -i '/^ExecStart=.*/i Environment="NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24,192.168.49.0/24,192.168.58.0/24,172.16.49.98"' /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl enable --now  docker.service

useradd mini
groupadd docker
usermod -a -G docker mini

cat >>  /home/mini/.bashrc << EOF
export http_proxy=http://172.16.49.98:80
export https_proxy=http://172.16.49.98:80
export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24,192.168.49.0/24,192.168.58.0/24,172.16.49.98
EOF


mkdir /home/mini/.docker/
cat > /home/mini/.docker/config.json << EOF
{
 "proxies":
 {
   "default":
   {
     "httpProxy": "http://172.16.49.98:80",
     "httpsProxy": "http://172.16.49.98:80",
     "noProxy": "localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24,192.168.49.0/24,192.168.58.0/24,172.16.49.98"
   }
 }
}
EOF
chown -R mini:mini /home/mini/.docker/
chown -R mini:mini /home/mini/.bashrc
systemctl restart docker

su - mini

minikube start --driver=docker

minikube status
kubectl cluster-info

kubectl run hello-world --image=amigoscode/kubernetes:hello-world --port=80
kubectl get pods -w
kubectl port-forward pod/hello-world 8080:80
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

yum -y install firefox
######################################
minikube ssh -n node2
minikube delete
#minikube start --nodes=2
minikube node add 
minikube ip --node node2
minikube logs
minikube tunnel
minikube service frontend
 
kubectl get all 
kubectl get nodes
kubectl exec -it pod/myapp2 -- bash
kubectl api-resources

kubectl scale --replicas=3 deployment/myapp3
kubectl rollout history deployment myapp3
kubectl rollout history deployment myapp3 --revision 4
kubectl rollout undo deployment myapp3 --to-revision 3

kubectl get pods --show-labels
kubectl get pods --selector  app=frontend
kubectl get pods -l app=customer -l tier=application
kubectl get pod -l 'app in (customer,order), tier notin (application)' --show-labels

kubectl get ep

kubectl create cm mycm01 --from-literal=key01=value01
kubectl replace --force -f configmap.yml
kubectl create secret generic mysec01 --from-literal=key01=value01
echo mypassword | base64
kubectl create secret docker-registry mydoc --docker-username=hamid --docker-password=pass  --docker-server=redhat.io
