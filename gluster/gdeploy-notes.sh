snapshot reserve

[selinux]
# yes

# [disktype]
# raid6

# [diskcount]
# 10

# [stripesize]
# 256

[tune-profile]
rhgs-sequential-io

# [snapshot]
# action=config
# snap_max_soft_limit=92
# snap_max_hard_limit=95
# auto_delete=disable
# activate_on_create=enable

# For setting default soft limits
#
# [quota]
# action=default-soft-limit
# volname=glustervol
# percent=85
#
#
# For limiting usage for volume
#
# [quota]
# action=limit-usage
# volname=glustervol
# path=/,/dir1
# size=5MB,6MB
#
#
# For limiting object count for volume
#
# [quota]
# action=limit-objects
# volname=glustervol
# path=/,/dir1
# number=10,20
#
#
# For setting alert-time
#
# [quota]
# action=alert-time
# volname=glustervol
# time=1W
#
#
# For setting soft-timeout
#
# [quota]
# action=soft-timeout
# volname=glustervol
# client_hosts=10.70.46.23,10.70.46.24
# time=100
#
#
#
# For setting hard-timeout
#
# [quota]
# action=hard-timeout
# volname=glustervol
# client_hosts=10.70.46.23,10.70.46.24
# time=100

# [RH-subscription]
# action=register
# activationkey=my_big_activation_key

# [RH-subscription]
# action=unregister

# [yum]
# action=install
# repos=<repos>
# packages=vi,glusterfs
# gpgcheck=no
# update=no
# ignore_yum_errors=no   # Do not continue if yum errors out.

