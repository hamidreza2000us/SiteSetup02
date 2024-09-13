#setting the required values
#yum -y install ceph-osd
OSDID=6
jvalue=$(ceph-volume lvm  list --format json) 
OSDRemove=$(echo $jvalue |  jq ".\"${OSDID}\"[0]".devices[0] | sed 's/\"//g' | sed 's/\/dev\///g')
OSDVG=$(echo $jvalue |  jq ".\"${OSDID}\"[0]"."vg_name" | sed 's/\"//g' )
OSDLV=$(echo $jvalue |  jq ".\"${OSDID}\"[0]"."lv_name" | sed 's/\"//g' )
FSID=$(echo $jvalue |  jq ".\"${OSDID}\"[0].\"tags\".\"ceph.osd_fsid\"" | sed 's/\"//g' )
echo -e "OSDID\tOSDDisk\t\t\t\tOSDVG\t\t\t\t\t\tOSDLV\t\t\t\tFSID" > /root/faultedDisks
echo -e "$OSDID\\t$OSDRemove\t$OSDVG\t$OSDLV\t$FSID" >> /root/faultedDisks
cat >> /root/faultedDisks << EOF
export OSDRemove=$OSDRemove
export OSDVG=$OSDVG
export OSDLV=$OSDLV
export FSID=$FSID
EOF
cat  /root/faultedDisks

#simulate remove the device
: '
echo 1 > /sys/block/${OSDRemove}/device/delete
sleep 10
systemctl restart ceph-osd@${OSDID} 
'

#replacing the failed disk
##confirm if the disk is really faluted
systemctl start ceph-osd@${OSDID} 
systemctl status ceph-osd@${OSDID} 
smartctl -H /dev/${OSDRemove} 
tail /var/log/ceph/ceph-osd.${OSDID}.log
ceph osd tree | grep -i down

#removing faulted disk
systemctl stop ceph-osd@${OSDID}
ceph osd out ${OSDID}

#check if it is back filling
ceph -w

#ceph osd crush remove osd.6
ceph auth del osd.${OSDID} 
ceph auth list | grep osd.${OSDID}
ceph osd rm osd.${OSDID}

#replace the disk
#in case you are rebooting the server to recognize the new disk
: '
ceph osd set noout
ceph osd unset noout
'

#add osd disk
ceph-volume lvm list /dev/${OSDRemove}
ceph-volume lvm prepare --bluestore --data ${OSDVG}/${OSDLV}
#in case you are going to  wipe existing data and setup new volume group
#or the solution above didn't work
: '
lvremove $OSDVG/$OSDLV
vgremove $OSDVG
pvremove /dev/${OSDRemove}
OSDID=6
jvalue=$(ceph-volume lvm  list --format json) 
OSDRemove=$(echo $jvalue |  jq ".\"${OSDID}\"[0]".devices[0] | sed 's/\"//g' | sed 's/\/dev\///g')
OSDVG=$(echo $jvalue |  jq ".\"${OSDID}\"[0]"."vg_name" | sed 's/\"//g' )
OSDLV=$(echo $jvalue |  jq ".\"${OSDID}\"[0]"."lv_name" | sed 's/\"//g' )
FSID=$(echo $jvalue |  jq ".\"${OSDID}\"[0].\"tags\".\"ceph.osd_fsid\"" | sed 's/\"//g' )
echo -e "OSDID\tOSDDisk\t\t\t\tOSDVG\t\t\t\t\t\tOSDLV\t\t\t\tFSID" > /root/replacedDisks
echo -e "$OSDID\\t$OSDRemove\t$OSDVG\t$OSDLV\t$FSID" >> /root/replacedDisks
cat  /root/replacedDisks
ceph-volume lvm prepare --bluestore --data /dev/${OSDRemove}
'

ceph osd set noup
ceph-volume lvm activate --bluestore ${OSDID} ${FSID}
ceph osd crush add ${OSDID} 1 host=$(hostname -s)
ceph osd unset noup

chown -R ceph:ceph /var/lib/ceph/osd
chown -R ceph:ceph /var/log/ceph
chown -R ceph:ceph /var/run/ceph
chown -R ceph:ceph /etc/ceph

systemctl enable ceph-osd@${OSDID}
systemctl start ceph-osd@${OSDID}

#temp commands
#echo $jvalue |  jq ".\"${OSDID}\"[0]"
#ceph-volume lvm list | grep -E "======|\[block|\[db|devices" | sed 's/\/dev\///g'
#ceph-volume lvm list /dev/sdo | grep '\[block\]' | sed -e 's#  [block]       /dev/##'

