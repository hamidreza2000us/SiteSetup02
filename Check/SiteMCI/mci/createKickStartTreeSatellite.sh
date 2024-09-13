#https://access.redhat.com/documentation/en-us/red_hat_satellite/6.6/html/content_management_guide/importing-kickstart-repositories_content-management

mkdir /mnt/cdrom
#mount -o loop,ro /mnt/Mount/ISOs/rhel-8.2-x86_64-dvd.iso /mnt/cdrom/
mount -o loop,ro /dev/cdrom /mnt/cdrom/
release=8.3
mkdir -p /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/kickstart
mkdir -p /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart
cp -a /mnt/cdrom/BaseOS/* /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/
cp -a /mnt/cdrom/AppStream/* /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/kickstart/
echo -e "${release}" >> /var/Mount/content/dist/rhel8/listing
echo -e "kickstart" >> /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/listing
echo -e "kickstart" >> /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/listing
cp /mnt/cdrom/.treeinfo /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/treeinfo
chmod 644 /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/treeinfo
cp /mnt/cdrom/.treeinfo /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/kickstart/treeinfo
chmod 644 /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/kickstart/treeinfo
cp -ra /mnt/cdrom/images /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/
cp -a /var/Mount/ISOs/rhel-${release}-x86_64-boot.iso /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/images/boot.iso

cp /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/treeinfo /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/treeinfo.org
head -n 6 /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/treeinfo.org > /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/treeinfo
cat >> /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/treeinfo << EOF
[general]
; WARNING.0 = This section provides compatibility with pre-productmd treeinfos.
; WARNING.1 = Read productmd documentation for details about new format.
arch = x86_64
family = Red Hat Enterprise Linux
name = Red Hat Enterprise Linux ${release}
packagedir = Packages
platforms = x86_64,xen
repository = .
timestamp = 1585988218
variant = BaseOS
variants = BaseOS
version = ${release}

[header]
type = productmd.treeinfo
version = 1.2

[images-x86_64]
efiboot.img = images/efiboot.img
initrd = images/pxeboot/initrd.img
kernel = images/pxeboot/vmlinuz

[images-xen]
initrd = images/pxeboot/initrd.img
kernel = images/pxeboot/vmlinuz

[release]
name = Red Hat Enterprise Linux
short = RHEL
version = ${release}

[stage2]
mainimage = images/install.img

[tree]
arch = x86_64
build_timestamp = 1585988218
platforms = x86_64,xen
variants = BaseOS

[variant-BaseOS]
id = BaseOS
name = BaseOS
packages = Packages
repository = .
type = variant
uid = BaseOS

EOF


cp /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/kickstart/treeinfo /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/kickstart/treeinfo.org
cat > /var/Mount/content/dist/rhel8/${release}/x86_64/appstream/kickstart/treeinfo << EOF
[general]
; WARNING.0 = This section provides compatibility with pre-productmd treeinfos.
; WARNING.1 = Read productmd documentation for details about new format.
arch = x86_64
family = Red Hat Enterprise Linux
name = Red Hat Enterprise Linux ${release}
packagedir = Packages
platforms = x86_64,xen
repository = .
timestamp = 1585988218
variant = AppStream
variants = AppStream
version = ${release}

[header]
type = productmd.treeinfo
version = 1.2

[release]
name = Red Hat Enterprise Linux
short = RHEL
version = ${release}

[tree]
arch = x86_64
build_timestamp = 1585988218
platforms = x86_64,xen
variants = AppStream

[variant-AppStream]
id = AppStream
name = AppStream
packages = Packages
repository = .
type = variant
uid = AppStream

EOF


######################################################################################################
SatHost=sat
Domain=idm.mci.ir
DefaultPass=Iahoora@123
IDMPass=Iahoora@123

#######################test####################################
ln -s /var/Mount/ /var/www/html/pub/RHEL
hammer product create --organization-id 1 --name RH
hammer content-view create --name vceph4 --label vceph4 --organization-id 1 

#################################################################################
#can also configure with ldaps
array=(${Domain//./ })
for i in "${array[@]}" ; do out+="dc=$i," ; done
output=${out::-1}
hammer auth-source ldap create --name ${IDMHost}.${Domain} --host ${IDMHost}.${Domain} --server-type free_ipa \
--account admin --account-password ${IDMPass} --base-dn ${output}  --onthefly-register true \
--attr-login uid  --attr-firstname givenName --attr-lastname sn --attr-mail mail
hammer realm create --name ${Domain^^} --realm-type "Red Hat Identity Management" --realm-proxy-id 1 --organization-id 1
#########################network config##################
###########################################################

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 \
--name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart ${release}" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel8/${release}/x86_64/baseos/kickstart/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart ${release}" --async 

hammer repository create --product RH --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 \
--name "Red Hat Enterprise Linux 8 for x86_64 - AppStream Kickstart ${release}" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel8/${release}/x86_64/appstream/kickstart/
hammer repository sync --organization-id 1 --product RH --name "Red Hat Enterprise Linux 8 for x86_64 - AppStream Kickstart ${release}" 

hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - BaseOS Kickstart ${release}"
hammer content-view add-repository --name vceph4  --organization-id 1 --repository "Red Hat Enterprise Linux 8 for x86_64 - AppStream Kickstart ${release}" 
hammer content-view publish --name vceph4 --organization-id 1 

hammer template add-operatingsystem --name "Kickstart default" --operatingsystem "RedHat-${release}"
#you need to associate the host some templates



##########################test#################################
#hammer content-view  version promote --organization-id 1  --content-view vceph4 --to-lifecycle-environment dev

hammer activation-key create --name kceph04 --organization-id 1 --lifecycle-environment Library --content-view vceph4
hammer activation-key update --name kceph04 --auto-attach false --organization-id 1
subsID=$(hammer --output csv --no-headers  subscription list | grep ",RH," | awk -F, '{print $1}')
#id=$( hammer activation-key add-subscription --name kceph04 --subscription-id ${subsID}  --organization-id 1)
hammer activation-key add-subscription --name kceph04 --subscription-id ${subsID}  --organization-id 1


hammer hostgroup create --name HGBase --lifecycle-environment Library   \
--architecture x86_64 --root-password ${DefaultPass} --organization-id 1 \
--partition-table "Kickstart default"  \
--domain ${Domain} --content-source ${SatHost}.${Domain} --realm ${Domain^^} 

hammer hostgroup set-parameter --hostgroup HGBase --name freeipa_server --parameter-type string --value ${IDMHost}.${Domain}
hammer hostgroup set-parameter --hostgroup HGBase --name freeipa_domain --parameter-type string --value ${Domain^^}
hammer hostgroup set-parameter --hostgroup HGBase  --name package_upgrade --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup HGBase  --name use-ntp --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup HGBase  --name time-zone --parameter-type string --value Asia/Tehran
hammer hostgroup set-parameter --hostgroup HGBase  --name ntp-server --parameter-type string --value ${IDMIP}
pubkey=$(curl -k https://${SatHost}.${Domain}:9090/ssh/pubkey)
hammer hostgroup set-parameter --hostgroup HGBase  --name remote_execution_ssh_keys  --parameter-type array --value "[${pubkey}]"
hammer hostgroup set-parameter --hostgroup HGBase  --name redhat_install_agent --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup HGBase  --name subscription_manager --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup HGBase  --name redhat_install_host_tools --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup HGBase  --name atomic --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup HGBase  --name subscription_manager_certpkg_url --parameter-type string --value http://${SatHost}.${Domain}/pub/katello-ca-consumer-latest.noarch.rpm
hammer hostgroup set-parameter --hostgroup HGBase  --name realm.realm_type --parameter-type string --value FreeIPA
hammer hostgroup set-parameter --hostgroup HGBase  --name enable-epel --parameter-type boolean --value false

hammer hostgroup create --name HGBareMetal --parent HGBase --pxe-loader 'Grub2 UEFI'   
hammer hostgroup create --name HGVirtual --parent HGBase --pxe-loader 'PXELinux BIOS'   

hammer hostgroup create --name HGPCeph4 --parent HGBareMetal --operatingsystem "RedHat-${release}" --content-view vceph4 --organization-id 1
hammer hostgroup set-parameter --hostgroup HGPCeph4  --name kt_activation_keys --parameter-type string --value kceph04
###########################################################


