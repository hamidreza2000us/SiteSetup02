#https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/content_management_guide/importing-kickstart-repositories_content-management
mkdir /mnt/cdrom
mount -o loop,ro /var/Mount/ISOs/rhgs-3.5-rhel-8-x86_64-dvd-354.iso /mnt/cdrom/
#mount -o loop,ro /dev/cdrom /mnt/cdrom/
release=3.5.4
mkdir -p /var/Mount/content/dist/rhel8/gluster/${release}/x86_64/kickstart
cp -a /mnt/cdrom/* /var/Mount/content/dist/rhel8/gluster/${release}/x86_64/kickstart/
echo -e "gluster" >> /var/Mount/content/dist/rhel8/listing
echo -e "${release}" >> /var/Mount/content/dist/rhel8/gluster/listing
echo -e "x86_64" >> /var/Mount/content/dist/rhel8/gluster/${release}/listing
echo -e "kickstart" >> /var/Mount/content/dist/rhel8/gluster/${release}/x86_64/listing

cp /mnt/cdrom/.treeinfo /var/Mount/content/dist/rhel8/gluster/${release}/x86_64/kickstart/treeinfo
chmod 655 /var/Mount/content/dist/rhel8/gluster/${release}/x86_64/kickstart

######################################################################################################
SatHost=satellite
Domain=idm.mci.ir

#######################test####################################
#ln -s /var/Mount/ /var/www/html/pub/RHEL
hammer product create --organization-id 1 --name Gluster
hammer content-view create --name vgluster --label vgluster --organization-id 1 

#########################network config##################

hammer repository create --product Gluster --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 1 \
--name "Red Hat Gluser Storage Kickstart ${release}" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel8/gluster/${release}/x86_64/kickstart
hammer repository sync --organization-id 1 --product Gluster --name "Red Hat Gluser Storage Kickstart ${release}" --async 

hammer content-view add-repository --name vgluster  --organization-id 1 --repository "Red Hat Gluser Storage Kickstart ${release}"
hammer content-view publish --name vgluster --organization-id 1 

#??????????????
#hammer template add-operatingsystem --name "Kickstart default" --operatingsystem "RedHat-${release}"
#you need to associate the host some templates

##########################test#################################
#hammer content-view  version promote --organization-id 1  --content-view vgluster --to-lifecycle-environment dev

hammer activation-key create --name kgluster --organization-id 1 --lifecycle-environment Library --content-view vgluster
hammer activation-key update --name kgluster --auto-attach false --organization-id 1
subsID=$(hammer --output csv --no-headers  subscription list | grep ",Gluster," | awk -F, '{print $1}')
#id=$( hammer activation-key add-subscription --name kgluster --subscription-id ${subsID}  --organization-id 1)
hammer activation-key add-subscription --name kgluster --subscription-id ${subsID}  --organization-id 1

 
#kickstart for this should have %end at end of %package and all %post script.
#you should also delete wget and ntp from the default packages
#UEFI is not working with my experience
#add @^Default_Gluster_Storage_Server group and also configure post to install satellite certificate (bug)
hammer template dump --name "Kickstart default" > /tmp/ks-default
cat > /tmp/ks-default-gluster << EOF
--- /tmp/ks-default  2021-08-19 00:07:34.456866963 +0430
+++ /tmp/ks-default-gluster  2021-08-19 00:07:53.797867752 +0430
@@ -219,15 +219,8 @@
 <%= snippet_if_exists(template_name + " custom packages") %>
 yum
 dhclient
-<% if use_ntp -%>
-ntp
--chrony
-<% else -%>
 chrony
--ntp
-<% end -%>
-wget
-@Core
+@^Default_Gluster_Storage_Server
 <% if os_major >= 6 -%>
 redhat-lsb-core
 <% end -%>
@@ -235,6 +228,7 @@
 <%=   snippet 'fips_packages' %>
 <% end -%>
 <%= section_end -%>
+%end

 <% if @dynamic -%>
 %pre
@@ -256,6 +250,7 @@
 <%#
 Main post script, if it fails the last post is still executed.
 %>
+%end
 %post --log=/root/install.post.log
 logger "Starting anaconda <%= @host %> postinstall"
 exec < /dev/tty3 > /dev/tty3
@@ -319,7 +314,7 @@
 <%= snippet 'insights' -%>
 touch /tmp/foreman_built
 <%= section_end -%>
-
+%end
 <%#
 The last post section halts Anaconda to prevent endless loop
 %>
@@ -340,7 +335,7 @@
   echo "calling home: build failed!"
   <%= indent(2, skip1: true) { snippet('built', :variables => { :endpoint => 'failed', :method => 'POST', :body_file => '/mnt/sysimage/root/install.post.log' }) } -%>
 fi
+%end

-sync
 <%= section_end -%>

EOF

patch /tmp/ks-default /tmp/ks-default-gluster
hammer template create --file /tmp/ks-default --name "Kickstart default gluster" --type "provision" --organization-id 1

#add installation media
hammer medium create --name gluster3.5.2 --path http://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel8/gluster/3.5.2/x86_64/kickstart --os-family Redhat
#add operating system
hammer os create  --name Gluser --major 3 --minor 5.2 --organization 'MCI' --partition-tables \
'Kickstart default' --media 'gluster3.5.2' --provisioning-templates 'Kickstart default gluster' --family 'Redhat'

hammer template add-operatingsystem --name "Kickstart default gluster" --operatingsystem "Gluster3.5.3"

hammer hostgroup create --name Gluster --parent Vir  --content-view vgluster --organization-id 1
hammer hostgroup set-parameter --hostgroup Gluster  --name kt_activation_keys --parameter-type string --value kgluster

