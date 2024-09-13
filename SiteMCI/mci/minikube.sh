subscription-manager unregister
yum clean all
subscription-manager register --org="MCI" --activationkey="KCent7" --force
yum install -y minikube docker conntrack

sed -i '/^ExecStart=.*/i Environment="HTTP_PROXY=http://artifactory.idm.mci.ir:80"' /usr/lib/systemd/system/docker.service
sed -i '/^ExecStart=.*/i Environment="HTTPS_PROXY=http://artifactory.idm.mci.ir:80"' /usr/lib/systemd/system/docker.service
sed -i '/^ExecStart=.*/i Environment="NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24"' /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl enable --now  docker.service

yum install --nogpgcheck -y kubectl

useradd mini
groupadd docker
systemctl restart docker
usermod -a -G docker mini

cat >>  /home/mini/.bashrc << EOF
export http_proxy=http://artifactory.idm.mci.ir:80
export https_proxy=http://artifactory.idm.mci.ir:80
export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24
EOF
su - mini

minikube start --driver=docker

firewall-cmd --add-port=80/tcp --add-port=443/tcp  --permanent
firewall-cmd --reload

#docker run  --rm -p 80:80 amigoscode/kubernetes:hello-world

