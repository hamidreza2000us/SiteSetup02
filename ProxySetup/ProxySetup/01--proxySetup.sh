#this script setup a Proxy server (Capsule) for a running foreman installation
#######################################################################################
git clone https://github.com/hamidreza2000us/proxysetup.git

bash ~/proxysetup/CO78-BaseProxyParameters.sh
source ~/proxysetup/variables.sh
ssh-copy-id root@$ProxyIP
scp -r ~/proxysetup root@$ProxyIP:~/
ssh $ProxyIP yum -y localinstall http://$ForemanHOSTNAME/pub/katello-ca-consumer-latest.noarch.rpm
ssh $ProxyIP subscription-manager register --org "myorg" --activationkey="mykey01"
ssh $ProxyIP bash ~/proxysetup/CO78-Foreman-proxy-BaseSystem.sh
ssh $ProxyIP bash ~/proxysetup/CO78-SetupChronyClient.sh 
ssh $ProxyIP bash ~/proxysetup/CO78-IDMRegister.sh
ssh $ProxyIP bash ~/proxysetup/CO78-ProxySetup.sh
scirpt=$(foreman-proxy-certs-generate --foreman-proxy-fqdn "$ProxyHOSTNAME" --certs-tar "/root/$ProxyHOSTNAME-certs.tar")
echo $script | sed -n '/foreman-installer \\/,$p' | sed 's/\\//g' > /tmp/proxyscript.sh

scp "/root/$ProxyHOSTNAME-certs.tar" root@$ProxyIP:~/
scp /tmp/proxyscript.sh root@$ProxyIP:/tmp/proxyscript.sh
ssh $ProxyIP bash /tmp/proxyscript.sh
CO78-ForemanInstaller.sh

hammer proxy content synchronize --id 2 --lifecycle-environment Library --organization-id 1
hammer proxy content synchronize --id 2 --lifecycle-environment dev --organization-id 1


