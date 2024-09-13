#https://access.redhat.com/documentation/en-us/red_hat_satellite/6.6/html/content_management_guide/importing-kickstart-repositories_content-management


mkdir -p /mnt/Mount/content/dist/rhel8/8.3/x86_64/appstream/kickstart
mkdir -p /mnt/Mount/content/dist/rhel8/8.3/x86_64/baseos/kickstart
cp -a /mnt/cdrom/BaseOS/* /mnt/Mount/content/dist/rhel8/8.3/x86_64/baseos/kickstart/
cp -a /mnt/cdrom/AppStream/* /mnt/Mount/content/dist/rhel8/8.3/x86_64/appstream/kickstart/
echo -e "8.3" >> /mnt/Mount/content/dist/rhel8/listing
echo -e "kickstart" >> /mnt/Mount/content/dist/rhel8/8.3/x86_64/baseos/listing
echo -e "kickstart" >> /mnt/Mount/content/dist/rhel8/8.3/x86_64/appstream/listing
cp /mnt/cdrom/.treeinfo /mnt/Mount/content/dist/rhel8/8.3/x86_64/baseos/kickstart/treeinfo
cp /mnt/cdrom/.treeinfo /mnt/Mount/content/dist/rhel8/8.3/x86_64/appstream/kickstart/treeinfo
cp -ra /mnt/cdrom/images /mnt/Mount/content/dist/rhel8/8.3/x86_64/baseos/kickstart/
cp -a /mnt/Mount/ISOs/rhel-8.3-x86_64-boot.iso /mnt/Mount/content/dist/rhel8/8.3/x86_64/baseos/kickstart/images/boot.iso
#edit files below based on redhat recommendations. https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html-single/installing_satellite_server_from_a_disconnected_network/index#importing-kickstart-repositories_rhel-8
#vi /mnt/Mount/content/content/dist/rhel8/8.3/x86_64/appstream/kickstart/treeinfo
#vi /mnt/Mount/content/dist/rhel8/8.3/x86_64/appstream/kickstart/treeinfo


mkdir /mnt/cdrom
#mount -o loop,ro /mnt/Mount/ISOs/rhel-8.2-x86_64-dvd.iso /mnt/cdrom/
mount -o loop,ro /dev/cdrom /mnt/cdrom/
release=8.2
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
cp -a /var/Mount/ISOs/rhel-8.3-x86_64-boot.iso /var/Mount/content/dist/rhel8/${release}/x86_64/baseos/kickstart/images/boot.iso

cp /var/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/treeinfo /var/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/treeinfo.org
head -n 6 /var/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/treeinfo.org > /var/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/treeinfo
cat >> /var/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/treeinfo < EOF
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











########################################################################
umount /mnt/cdrom/
mount rhel-server-7.9-x86_64-dvd.iso /mnt/cdrom
cd /mnt/cdrom/
mkdir -p /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/kickstart/
cp -a * /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/kickstart/
echo "7.9" > /mnt/Mount/content/dist/rhel/server/7/listing
echo "x86_64" > /mnt/Mount/content/dist/rhel/server/7/7.9/listing
echo "kickstart" > /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/listing
cp .treeinfo /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/kickstart/treeinfo

########################################################################
iso=CentOS-7-x86_64-DVD-2009.iso
family=centos
major=7
minor=9
arch=x86_64
SatHost=satellite
Domain=idm.mci.ir
version="CentOS Linux Kickstart ${major}.${minor}"
 
umount /mnt/cdrom/
cd /var/Mount/ISOs
mount $iso /mnt/cdrom
cd /mnt/cdrom/
mkdir -p /var/Mount/content/dist/${family}/server/${major}/${major}.${minor}/${arch}/kickstart/
cp -a * /var/Mount/content/dist/${family}/server/${major}/${major}.${minor}/${arch}/kickstart/
#wget http://centos.mirror.globo.tech/7.9.2009/os/x86_64/images/boot.iso
cp /var/Mount/ISOs/boot.iso /var/Mount/content/dist/centos/server/7/7.9/x86_64/kickstart/images/

#add dirsto to listing if required
echo "${major}.${minor}" > /var/Mount/content/dist/${family}/server/${major}/listing
echo "${arch}" > /var/Mount/content/dist/${family}/server/${major}/${major}.${minor}/listing
echo "kickstart" > /var/Mount/content/dist/${family}/server/${major}/${major}.${minor}/${arch}/listing
cp .treeinfo /var/Mount/content/dist/${family}/server/${major}/${major}.${minor}/${arch}/kickstart/treeinfo


hammer repository create --product Cent7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 \
--name "${version}" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/${family}/server/${major}/${major}.${minor}/${arch}/kickstart/

hammer repository sync --organization-id 1 --product Cent7 --name "${version}" --async

hammer content-view add-repository --name VCent7  --organization-id 1 --repository "${version}"
hammer content-view publish --name VCent7 --organization-id 1 

hammer template add-operatingsystem --name "Kickstart default" --operatingsystem "RedHat-${release}"

#hammer os create --family 'Redhat' --major ${major} --minor ${major}.${minor} --organization 'MCI' --partition-tables 'Kickstart default' --media 'gluster3.5.2' \
#--provisioning-templates 'Kickstart default gluster' --name Gluser

