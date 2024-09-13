#on all hosts
yum install pcs fence-agents-all
yum install corosync-qdevice
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload
systemctl enable --now pcsd
echo redhat | passwd --stdin hacluster

pcs host auth node1.example.com \
> node2.example.com \
> node3.example.com
Username: hacluster
Password: redhat


pcs cluster setup mycluster --start \
> node1.example.com \
> node2.example.com \
> node3.example.com
#quorum wait_for_all=1 
#> auto_tie_breaker=1 \
#> last_man_standing=1 
#pcs cluster node add node4.example.com
#pcs cluster node remove node4.example.com
pcs cluster enable --all
#pcs cluster disable node2.example.com
pcs cluster status
#pcs status
pcs cluster start --all
#pcs cluster stop --all

pcs quorum status
#corosync-quorumtool
#pcs quorum update \
#> auto_tie_breaker=1 \
#> last_man_standing=1 \
#> wait_for_all=1
#pcs quorum update wait_for_all=0

pcs stonith create fence_device_name fence_ipmilan \
> pcmk_host_list=node_private_fqdn \
> ip=node_IP_BMC \
> username=username \
> password=password \
> lanplus=1 \
> power_timeout=180
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
pcs stonith status

pcs node standby node1.example.com
pcs node unstandby --all

pcs resource list
#pcs status resources
#pcs resource describe Filesystem
pcs resource create myfs Filesystem \
> device=/dev/sdb1 \
> directory=/var/www/html \
> fstype=xfs \
> --group=mygroup \
op monitor interval=10s timeout=15s on-fail=fence \
meta migration-threshold=5 priority=100
pcs resource defaults update resource-stickiness=1000
#pcs resource defaults
#pcs resource defaults update resource-stickiness=
#pcs resource defaults update priority=1
#pcs resource create webip IPaddr2 \
#> ip=172.25.99.80 \
#> cidr_netmask=24 \
#> --group=myweb
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
#pcs constraint location A prefers node
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
#PCMK_logfile => logFIleLocation
#PCMK_logfacility
#PCMK_logpriority
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

yum install pcs corosync-qnetd
passwd hacluster
systemctl enable --now pcsd
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload
pcs qdevice setup model net --enable --start
#from Other node / use lms instead of ffsplit preferably
pcs host auth host.example.net
pcs quorum device add model net host=host.example.net \
> algorithm=ffsplit
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

#to activate lvm-ha
/etc/lvm/lvm.conf
system_id_source = "uname"
lvm systemid
pcs resource create halvm LVM-activate \
> vgname=shared_vg vg_access_mode=system_id --group=hafs
pcs resource create xfsfs Filesystem \
> device=/dev/shared_vg/ha_lv directory=/data fstype=xfs --group=hafs

##to activate lvm-cluster
#yum install dlm lvm2-lockd
#pcs resource create dlm ocf:pacemaker:controld \
#> op monitor interval=30s on-fail=fence --group=lock_group
#pcs resource create lvmlockd ocf:heartbeat:lvmlockd \
#> op monitor interval=30s on-fail=fence --group=lock_group
#pcs resource clone lock_group interleave=true
#pcs status --full
#vgcreate --shared lvmsharedvg /dev/sdb
##on all cluster nodes
#vgchange --lock-start lvmsharedvg
#lvcreate --activate sy -L500G -n lv1 lvmsharedvg
#pcs resource create sharedlv1 LVM-activate \
#> vgname=lvmsharedvg lvname=lv1 activation_mode=shared vg_access_mode=lvmlockd \
#> --group=LVMshared_group
#pcs resource clone LVMshared_group interleave=true
#pcs constraint order start \
#> lock_group-clone then LVMshared_group-clone
#pcs constraint colocation add \
#> LVMshared_group-clone with lock_group-clone

#yum install gfs2-utils
#mkfs.gfs2 -t examplecluster:examplegfs2 \
#> -j 3 -J 128 /dev/lvmsharedvg/lv1
#pcs resource create clusterfs Filesystem \
#> device=/dev/lvmsharedvg/lv1 directory=/data fstype=gfs2 \
#> on-fail=fence --group=LVMshared_group
#pcs property set no-quorum-policy=freeze
#gfs2_edit -p journals /dev/lvmsharedvg/lv1
#gfs2_jadd -j 3 -J 256 /dev/lvmsharedvg/lv1
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







