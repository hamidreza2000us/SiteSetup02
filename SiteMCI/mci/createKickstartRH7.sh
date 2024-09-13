#https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/content_management_guide/importing-kickstart-repositories_content-management
mkdir /mnt/cdrom
mount -o loop,ro /var/Mount/ISOs/rhel-server-7.9-x86_64-dvd.iso /mnt/cdrom/
#mount -o loop,ro /dev/cdrom /mnt/cdrom/
release=7.9
mkdir -p /var/Mount/content/dist/rhel/server/7/${release}/x86_64/kickstart
cp -a /mnt/cdrom/* /var/Mount/content/dist/rhel/server/7/${release}/x86_64/kickstart/
echo -e "${release}" >> /var/Mount/content/dist/rhel/server/7/listing
echo -e "x86_64" >> /var/Mount/content/dist/rhel/server/7/${release}/listing
echo -e "kickstart" >> /var/Mount/content/dist/rhel/server/7/${release}/x86_64/listing

cp /mnt/cdrom/.treeinfo /var/Mount/content/dist/rhel/server/7/${release}/x86_64/kickstart/treeinfo
chmod 655 /var/Mount/content/dist/rhel/server/7/${release}/x86_64/kickstart

######################################################################################################
SatHost=satellite
Domain=idm.mci.ir
DefaultPass=Iahoora@123
IDMPass=Iahoora@123

#######################test####################################
#ln -s /var/Mount/ /var/www/html/pub/RHEL
hammer product create --organization-id 1 --name RH7
hammer content-view create --name vrh7 --label vrh7 --organization-id 1 

#########################network config##################

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 \
--name "Red Hat Enterprise Linux 7 Server Kickstart ${release}" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7.9/x86_64/kickstart/
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Enterprise Linux 7 Server Kickstart ${release}" --async 

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat Enterprise Linux 7 Server - Optional (RPMs)" \
--url  https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/optional/os/
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Enterprise Linux 7 Server - Optional (RPMs)" --async


hammer content-view add-repository --name vrh7  --organization-id 1 --repository "Red Hat Enterprise Linux 7 Server Kickstart ${release}"
hammer content-view publish --name vrh7 --organization-id 1 

#??????????????
#hammer template add-operatingsystem --name "Kickstart default" --operatingsystem "RedHat-${release}"
#you need to associate the host some templates

##########################test#################################
#hammer content-view  version promote --organization-id 1  --content-view vrh7 --to-lifecycle-environment dev

hammer activation-key create --name krh7 --organization-id 1 --lifecycle-environment Library --content-view vrh7
hammer activation-key update --name krh7 --auto-attach false --organization-id 1
subsID=$(hammer --output csv --no-headers  subscription list | grep ",RH," | awk -F, '{print $1}')
#id=$( hammer activation-key add-subscription --name krh7 --subscription-id ${subsID}  --organization-id 1)
hammer activation-key add-subscription --name krh7 --subscription-id ${subsID}  --organization-id 1

hammer hostgroup create --name HRH7 --parent HGBareMetal --operatingsystem "RedHat ${release}" --content-view vrh7 --organization-id 1
hammer hostgroup set-parameter --hostgroup HRH7  --name kt_activation_keys --parameter-type string --value krh7