#!/bin/bash
#This script assume you need to login to on premise quay.io and get a backup of the files
#you need to have podman installed
#you need to have jq installed
#yum install -y podman jq
yum install -y jq
sourceRegistry="quay.myhost.com"
username=hamid
password=Iahoora@123
podman login $sourceRegistry -u ${username} -p ${password}
mkdir /root/backup
cd /root/backup
allImages=$(podman search $sourceRegistry/ | awk '{print $2}' | tail -n+2)
for image in $allImages
do
  repoUser=$(echo $image | awk -F/ '{print $2}')
  repoImage=$(echo $image | awk -F/ '{print $3}')
  tags=$(curl -k -su $username:$password https://$sourceRegistry/v1/repositories/$repoUser/$repoImage/tags | sed 's/{//g' | awk -F: '{print $1}' | sed 's/\"//g')
  for tag in $tags
  do
    podman pull $image:$tag
    podman save $image:$tag -o $image:$tag.tar.gz
  done
done
