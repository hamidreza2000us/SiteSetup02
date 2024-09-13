#https://access.redhat.com/documentation/en-us/red_hat_satellite/6.6/html/content_management_guide/importing-kickstart-repositories_content-management

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










