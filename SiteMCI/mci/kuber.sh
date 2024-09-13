################################on all nodes###################################
swapoff -a
lvremove -f centos_$(hostname -s)/swap
sed -i '/swap.*defaults/d' /etc/fstab
sed -i "s|rd.lvm.lv=centos_$(hostname -s)/swap||g" /etc/default/grub
grub2-mkconfig > /boot/grub2/grub.cfg

#cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
#overlay
#br_netfilter
#EOF
#modprobe overlay
#modprobe br_netfilter
## Setup required sysctl params, these persist across reboots.
#cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
#net.bridge.bridge-nf-call-iptables  = 1
#net.ipv4.ip_forward                 = 1
#net.bridge.bridge-nf-call-ip6tables = 1
#EOF
## Apply sysctl params without reboot
#sysctl --system
#yum install -y containerd.io
#mkdir -p /etc/containerd
#containerd config default | sudo tee /etc/containerd/config.toml
#sed -i "s/systemd_cgroup = false/systemd_cgroup = true/" /etc/containerd/config.toml
#systemctl restart containerd
#systemctl status containerd

yum install docker -y
systemctl enable --now docker

yum install -y kubeadm kubelet kubectl --disableexcludes=kubernetes
#systemctl daemon-reload
systemctl enable --now kubelet
firewall-cmd --permanent --zone=public  --add-port=6783/tcp --add-port=6784/tcp --add-port=6443/tcp --add-port=2379-2380/tcp --add-port=10250/tcp --add-port=10251/tcp  --add-port=10252/tcp --add-port=10255/tcp --add-port=30000-32767/tcp --add-port=2375-2377/tcp --add-port=7946/udp --add-port=4789/udp
firewall-cmd --reload
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

docker login https://artifactory.idm.mci.ir -u readonly -p Readonly@123

curl -L4 -x http://artifactory.idm.mci.ir:80 https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n') -o weave.yaml
for image in $(grep image: weave.yaml | awk '{print $2}') 
do
  noQuoteImage=$(echo $image | tr -d \'\") 
  docker pull  artifactory.idm.mci.ir/$noQuoteImage 
  docker tag artifactory.idm.mci.ir/$noQuoteImage $noQuoteImage 
done
kubectl completion bash > /etc/bash_completion.d/kubectl
#####################################on all master nodes/FIXME######################################

docker pull artifactory.idm.mci.ir/k8s/coredns/coredns:v1.8.6
docker tag artifactory.idm.mci.ir/k8s/coredns/coredns:v1.8.6 artifactory.idm.mci.ir/k8s/coredns:v1.8.6
#########################################on master node only ##################################
#kubeadm init --apiserver-advertise-address=$(hostname -i ) --pod-network-cidr=10.5.0.0/16 --image-repository artifactory.idm.mci.ir/k8s
##kubeadm join 172.20.29.153:6443 --token gdi9xl.o11jzn5fj3lsil4p  --discovery-token-ca-cert-hash sha256:8755fca3efbe1ae05a47010cf5267bb06ad8dc459597f54b1ccaf925bb225a13
##openssl x509 -in /etc/kubernetes/pki/ca.crt -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256
##kubeadm token create
kubeadm init --control-plane-endpoint $(hostname -i ):6443 --upload-certs --image-repository artifactory.idm.mci.ir/k8s
##kubeadm init phase upload-certs --upload-certs
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f weave.yaml

###################################on other nodes#######################################
#copy the join scripts to the nodes
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


