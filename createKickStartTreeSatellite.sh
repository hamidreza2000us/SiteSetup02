mkdir /mnt/cdrom
mount -o loop,ro /mnt/Mount/ISOs/rhel-8.3-x86_64-dvd.iso /mnt/cdrom/
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



mount -o loop,ro /mnt/Mount/ISOs/rhel-8.2-x86_64-dvd.iso /mnt/cdrom/
mkdir -p /mnt/Mount/content/dist/rhel8/8.2/x86_64/appstream/kickstart
mkdir -p /mnt/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart
cp -a /mnt/cdrom/BaseOS/* /mnt/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/
cp -a /mnt/cdrom/AppStream/* /mnt/Mount/content/dist/rhel8/8.2/x86_64/appstream/kickstart/
echo -e "8.2" >> /mnt/Mount/content/dist/rhel8/listing
echo -e "kickstart" >> /mnt/Mount/content/dist/rhel8/8.2/x86_64/baseos/listing
echo -e "kickstart" >> /mnt/Mount/content/dist/rhel8/8.2/x86_64/appstream/listing
cp /mnt/cdrom/.treeinfo /mnt/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/treeinfo
cp /mnt/cdrom/.treeinfo /mnt/Mount/content/dist/rhel8/8.2/x86_64/appstream/kickstart/treeinfo
cp -ra /mnt/cdrom/images /mnt/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/
cp -a /mnt/Mount/ISOs/rhel-8.3-x86_64-boot.iso /mnt/Mount/content/dist/rhel8/8.2/x86_64/baseos/kickstart/images/boot.iso


umount /mnt/cdrom/
mount rhel-server-7.9-x86_64-dvd.iso /mnt/cdrom
cd /mnt/cdrom/
mkdir -p /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/kickstart/
cp -a * /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/kickstart/
echo "7.9" > /mnt/Mount/content/dist/rhel/server/7/listing
echo "x86_64" > /mnt/Mount/content/dist/rhel/server/7/7.9/listing
echo "kickstart" > /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/listing
cp .treeinfo /mnt/Mount/content/dist/rhel/server/7/7.9/x86_64/kickstart/treeinfo

