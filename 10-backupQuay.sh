#!/bin/bash
#This script assume you need to login to on premise quay.io and get a backup of the files
#you need to have podman installed
#you need to have jq installed
#yum install -y podman jq
yum install -y jq
sourceRegistry="quay.myhost.com"
username=admin
password=Iahoora@123

sudo yum -y install sshpass
sudo mkdir -p /etc/docker/certs.d/quay.myhost.com/
sudo sshpass -p Iahoora@123  scp -o  StrictHostKeyChecking=no quay.myhost.com:/var/quay/config/ssl.crt /etc/docker/certs.d/quay.myhost.com/ca.crtsudo update-ca-trust
podman login $sourceRegistry -u ${username} -p ${password}

#mkdir /root/backup
#cd /root/backup
allImages=$(podman search $sourceRegistry/ | awk '{print $2}' | tail -n+2)
for image in $allImages
do
  repoUser=$(echo $image | awk -F/ '{print $2}')
  repoImage=$(echo $image | awk -F/ '{print $3}')
  mkdir -p /mnt/Mount/Containers/$repoUser
  tags=$(curl -k -su $username:$password https://$sourceRegistry/v1/repositories/$repoUser/$repoImage/tags | jq 'keys[]'  | sed 's/\"//g' )
  for tag in $tags
  do
    podman pull $image:$tag
    podman save $image:$tag -o /mnt/Mount/Containers/$repoUser/$(basename ${image})_$tag.tar.gz
  done
done

#make an organization with name rhceph
#restore backup to quay
for i in $(ls) 
do 
  image=$(echo $i | awk -F_ '{print $1":"$2}' | sed 's/.tar.gz//') 
  podman load -i $i 
done
for i in $(podman images | tail -n +2 |  awk '{print $1":"$2}' | grep quay.myhost.com ) 
do 
  podman push $i  
done

