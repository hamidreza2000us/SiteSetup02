yum install -y pcs pacemaker fence-agents-all corosync-qdevice
#becuase of a bug in corosync
yum update -y
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload
systemctl enable --now pcsd
echo redhat | passwd --stdin hacluster

pcs host auth pcs801.idm.mci.ir  pcs802.idm.mci.ir -u hacluster -p redhat

pcs cluster setup mycluster --start \
 pcs801.idm.mci.ir \
 pcs802.idm.mci.ir 
 quorum wait_for_all=1 \
 auto_tie_breaker=1 \
 last_man_standing=1 

pcs cluster enable --all
#pcs cluster node add node4.example.com
#pcs cluster node remove node4.example.com
#pcs cluster disable node2.example.com
#pcs cluster status
#pcs status
#pcs cluster start --all
#pcs cluster stop --all

#pcs quorum status
#corosync-quorumtool
#pcs quorum update \
# auto_tie_breaker=1 \
# last_man_standing=1 \
# wait_for_all=1
#pcs quorum update wait_for_all=0

# pcs stonith create ilo5-server5 fence_ilo5
#pcs stonith create fence_device_name fence_ipmilan \
# pcmk_host_list=node_private_fqdn \
# ip=node_IP_BMC \
# username=username \
# password=password \
# lanplus=1 \
# power_timeout=180

#pcs stonith status
pcs stonith create vmfence fence_vmware_rest ipaddr=rhvm.idm.mci.ir ssl_insecure=1 login=Administrator@VSPHERE.LOCAL passwd=Iahoora@123
#to test the fencing
#time fence_vmware_soap -o reboot -a 172.20.29.130 -l Administrator@VSPHERE.LOCAL -p Iahoora@123 --ssl-insecure  -z -n pcs802.idm.mci.ir
#add pcmk_host_map if the hostname and vmname is different
#fence_vmware_soap -a rhvm.idm.mci.ir  -l Administrator@VSPHERE.LOCAL -p Iahoora@123 --ssl-insecure -o list
#pcs stonith create vmfence fence_vmware_soap pcmk_host_map="pcs801.idm.mci.ir:pcs801.idm.mci.ir;pcs802.idm.mci.ir:pcs802.idm.mci.ir" ipaddr=rhvm.idm.mci.ir ssl=1 login=Administrator@VSPHERE.LOCAL passwd=Iahoora@123

#pcmk_delay_base=30s
#pcmk_reboot_timeout=60
#pcs stonith delete fence_deletednode
#pcs stonith list
#pcs stonith describe fence_rhevm
#/usr/sbin/fence_*
#pcs stonith fence nodename
#pcs property set stonith-timeout=180s priority-fencing-delay=40s
#pcs stonith config fence_node1
#pcs stonith update fence_node2 pcmk_host_list=node2.example.com pcmk_delay_base=25s pcmk_delay_max=40s
#pcs stonith level add 1 node1.example.com fence_ipmi_node1
#pcs stonith level
#pcs stonith level remove 2 node1.example.com
#pcs stonith level clear node1.example.com
##two fending device at the same time
#pcs stonith level add 1 node1.example.com \
#> fence_apcA_node1,fence_apcB_node1

#pcs node standby node1.example.com
#pcs node unstandby --all

#pcs resource list
pcs resource defaults update resource-stickiness=1000

#to activate lvm-ha on all nodes
sed -i 's/system_id_source = "none"/system_id_source = "uname"/g' /etc/lvm/lvm.conf
#lvm systemid
diskname=sdb
parted -s -a optimal /dev/${diskname} mklabel gpt mkpart primary  2048 100%
 pvcreate /dev/${diskname}1
 vgcreate SHRDGRP /dev/${diskname}1
 lvcreate -n SHRDLV1 -L 100%FREE SHRDGRP
udevadm settle
mkfs.xfs /dev/SHRDGRP/SHRDLV1

#preferably reboot both nodes 

pcs resource create VIPIP ocf:heartbeat:IPaddr2 ip=172.20.29.144 cidr_netmask=27 run_arping=1 monitor_retries=3 --group=HAGRP
pcs resource create HALVM ocf:heartbeat:LVM-activate \
 vgname=SHRDGRP vg_access_mode=system_id --group=HAGRP
pcs resource create HAFS ocf:heartbeat:Filesystem \
 device=/dev/SHRDGRP/SHRDLV1 directory=/mnt fstype=xfs --group=HAGRP \
 op monitor interval=10s timeout=15s on-fail=fence \
 meta migration-threshold=5 priority=100
#pcs constraint location HAGRP prefers pcs801.idm.mci.ir=500

#pcs status resources
#pcs resource describe Filesystem

#pcs resource defaults
#pcs resource defaults update resource-stickiness=
#pcs resource defaults update priority=1

#pcs resource update myfs device=/dev/sda1
#pcs resource delete myfs
#pcs resource op add webserver \
#> monitor interval=10s timeout=15s on-fail=fence
#pcs resource group add/remove mygroup myresource
#pcs resource disable/enable myresource
#pcs resource move myresource node2.example.com
#pcs resource ban myresource node2.example.com

#pcs resource failcount show my_resource
#pcs resource cleanup my_resource

#pcs constraint list
#pcs constraint list --full
#pcs resource clear myresource node2.example.com
#pcs constraint order A then B

#pcs constraint location A prefers node=500
#pcs constraint location A avoids node
#pcs constraint colocation add B with A
#pcs constraint colocation add B with A -INFINITY
#pcs constraint delete location-myweb-node.example.com-100
#crm_simulate -sL

#echo >> /etc/corosync/corosync.conf << EOF
#logging {
#  to_logfile: yes
#  logfile: /var/log/cluster/corosync.log
#  to_stderr: yes
#  syslog_priority: debug
#}
#EOF
#pcs cluster sync
##on each node
#pcs cluster reload corosync

#/etc/sysconfig/pacemaker
#PCMK_logfile=/var/log/pacemaker/pacemaker.log
#PCMK_logfacility=daemon
#PCMK_logpriority=notice
#PCMK_debug=no
##restart the cluster or put them in standby mode
#pcs cluster stop --all
#pcs cluster start --all

#/usr/share/pacemaker/alerts
#pcs alert create \
#> path=/usr/share/pacemaker/alerts/sample_alert.sh id=myalert
#pcs alert update alert-id [options [option=value] ...]
#pcs alert show
#pcs alert recipient add myalert value=email_one@example.com
#pcs alert remove myalert

#pcs resource create importantgroup-mailto MailTo \
#> email=admin@example.com \
#> subject="importantgroup notification" \
#> --group=importantgroup

yum install -y pcs corosync-qnetd
echo redhat | passwd --stdin hacluster
systemctl enable --now pcsd
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload
pcs qdevice setup model net --enable --start
#from Other node / use lms instead of ffsplit preferably
pcs host auth pcs803 -u hacluster -p redhat
pcs quorum device add model net host=pcs803 \
 algorithm=ffsplit
#on qnet host
pcs qdevice status net

#iscsi skipped

#multipath review
#yum install device-mapper-multipath
#mpathconf --enable --with_multipathd y
##wwn of a disk
#udevadm info /dev/sda | grep ID_SERIAL 
#multipath -t
##remove the path from running config
#multipath -f <multipath_device>
##remove all remnant device
#multipath -F



##to activate lvm-cluster
yum install -y dlm lvm2-lockd
pcs resource create dlm ocf:pacemaker:controld \
 op monitor interval=30s on-fail=fence --group=lock_group
pcs resource create lvmlockd ocf:heartbeat:lvmlockd \
 op monitor interval=30s on-fail=fence --group=lock_group
pcs resource clone lock_group interleave=true
pcs status --full
vgcreate --shared lvmsharedvg /dev/sdc
#on all cluster nodes
vgchange --lock-start lvmsharedvg
lvcreate --activate sy -L5G -n lv1 lvmsharedvg
pcs resource create sharedlv1 LVM-activate \
 vgname=lvmsharedvg lvname=lv1 activation_mode=shared vg_access_mode=lvmlockd \
 --group=LVMshared_group
pcs resource clone LVMshared_group interleave=true
pcs constraint order start \
 lock_group-clone then LVMshared_group-clone
pcs constraint colocation add \
 LVMshared_group-clone with lock_group-clone

yum install -y gfs2-utils
mkfs.gfs2 -t mycluster:gfs21  -j 2 -J 128  /dev/lvmsharedvg/lv1
pcs resource create clusterfs Filesystem \
 device=/dev/lvmsharedvg/lv1 directory=/mnt fstype=gfs2 \
 op monitor on-fail=fence --group=LVMshared_group
 
pcs property set no-quorum-policy=freeze
#gfs2_edit -p journals /dev/lvmsharedvg/lv1
#gfs2_jadd -j 2 -J 256 /dev/lvmsharedvg/lv1
#gfs2_grow /dev/lvmsharedvg/lv1
#tunegfs2 -l /dev/lvmsharedvg/lv1
#tunegfs2 -o locktable=newcluster:examplegfs2 /dev/lvmsharedvg/lv1

##pcs cluster link add \
#> node1.example.com=192.168.100.211 \
#> node2.example.com=192.168.100.212 \
#> node3.example.com=192.168.100.213 \
#> node4.example.com=192.168.100.214
##identify link id from /etc/corosync/corosync.conf 
#pcs cluster link remove 3