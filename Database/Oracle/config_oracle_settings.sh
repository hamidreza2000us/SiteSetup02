#/bin/bash
#https://access.redhat.com/labs/rheltfo/
processinput=131072
groupinput=oinstall

AllMemory=$(free -g | awk '/Mem/ {print $2}')
meminput=$(expr $AllMemory \* 75 / 100)

automated='false'
if [ $# -eq 1 ]
  then
  if [ $1 == 'automated' ]
    then
    automated='true'
  fi
fi

if [ $automated != 'true' ]; then
read -rp "SGA Size to set: ($meminput): " choice; [[ -n "${choice}"  ]] &&  export meminput="$choice";
read -rp "Oracle Max Process to set: ($processinput): " choice; [[ -n "${choice}"  ]] &&  export processinput="$choice";
read -rp "Oracle Main Group to set: ($groupinput): " choice; [[ -n "${choice}"  ]] &&  export groupinput="$choice";
fi

if [ $automated != 'true' ]; then
while true; do
    read -p "Will you continue? [Y/N]" yn
    case $yn in
        [Yy] )
            break
            ;;
        [Nn] )
            exit
            break
            ;;
    esac
done
fi

function commentExisting {
    params=("$@")
    params=("${params[@]:1}")
    for f in $(ls "$1"); do
        confile="$1/$f"
        for p in ${params[@]}; do
            sed -Ei 's/'$p'/# &/g' $confile
        done
    done
}

sysctl_check="/etc/sysctl.d"
limits_check="/etc/security/limits.d"
sysctl_conf='/etc/sysctl.conf'
limits_conf='/etc/security/limits.conf'

currentTimestamp=`date +%y-%m-%d-%H:%M:%S`
echo "Backing up configuration files."

backup="/etc/default/grub.$currentTimestamp.bak"
cp "/etc/default/grub" $backup

backup="$sysctl_conf.$currentTimestamp.bak"
cp $sysctl_conf $backup

backup="$limits_conf.$currentTimestamp.bak"
cp $limits_conf $backup

sysctl_params=(
    "vm.swappiness\s*="
    "vm.dirty_background_ratio\s*="
    "vm.dirty_ratio\s*="
    "vm.dirty_expire_centisecs\s*="
    "vm.dirty_writeback_centisecs\s*="
    "vm.nr_hugepages\s*="
    "vm.hugetlb_shm_group\s*="
    "kernel.shmmax\s*="
    "kernel.shmall\s*="
    "kernel.shmmni\s*="
    "kernel.sem\s*="
    "kernel.numa_balancing\s*="
	"fs.file-max\s*="
	"kernel.panic_on_oops\s*="
	"net.core.rmem_default\s*="
	"net.core.rmem_max\s*="
	"net.core.wmem_default\s*="
	"net.core.wmem_max\s*="
	"net.ipv4.conf.all.rp_filter\s*="
	"net.ipv4.conf.default.rp_filter\s*="
	"fs.aio-max-nr\s*="
	"net.ipv4.ip_local_port_range\s*="
    )

limits_params=(
    "oracle\s+soft\s+memlock\s+"
    "oracle\s+hard\s+memlock\s+"
    "oracle\s+hard\s+nofile\s+"
    "oracle\s+soft\s+nproc\s+"
    "oracle\s+hard\s+nproc\s+"
    "oracle\s+soft\s+stack\s+"
    "oracle\s+hard\s+stack\s+"
    )
commentExisting $sysctl_check ${sysctl_params[@]}
commentExisting $limits_check ${limits_params[@]}

# Shared Memory
mem=$(free -b | awk '/Mem/ {print $2}')
page=$(getconf PAGE_SIZE)
all=$(expr $mem \* 75 / 100 / $page + 1)
max=$(expr $all \* $page)

# HugePages
hugepagesize=$(grep Hugepagesize /proc/meminfo | awk '{print $2}')
SGA=$[$meminput * 1024 ** 2]
numberOfHugePages=$[$SGA/$hugepagesize]

# GID
gid=$(getent group $groupinput | awk -F ":" '{print $3}')

file="$sysctl_conf"

cat > "$file" << EOF


# Settings for oracle
# Memory settings
vm.swappiness = 10
vm.dirty_background_ratio = 3
vm.dirty_ratio = 40
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100

# HugePages
vm.nr_hugepages = $numberOfHugePages
vm.hugetlb_shm_group = $gid

# Shared Memory
kernel.shmmax = $max
kernel.shmall = $all
kernel.shmmni = 4096

# Semaphores
kernel.sem = 250 32000 100 128

# NUMA Balancing
kernel.numa_balancing = 0

# oracle-rdbms-server-11gR2-preinstall setting for fs.file-max is 6815744
fs.file-max = 6815744

# oracle-rdbms-server-11gR2-preinstall setting for kernel.panic_on_oops is 1 per Orabug 19212317
kernel.panic_on_oops = 1

# oracle-rdbms-server-11gR2-preinstall setting for net.core.rmem_default is 262144
net.core.rmem_default = 262144

# oracle-rdbms-server-11gR2-preinstall setting for net.core.rmem_max is 4194304
net.core.rmem_max = 4194304

# oracle-rdbms-server-11gR2-preinstall setting for net.core.wmem_default is 262144
net.core.wmem_default = 262144

# oracle-rdbms-server-11gR2-preinstall setting for net.core.wmem_max is 1048576
net.core.wmem_max = 1048576

# oracle-rdbms-server-11gR2-preinstall setting for net.ipv4.conf.all.rp_filter is 2
net.ipv4.conf.all.rp_filter = 2

# oracle-rdbms-server-11gR2-preinstall setting for net.ipv4.conf.default.rp_filter is 2
net.ipv4.conf.default.rp_filter = 2

# oracle-rdbms-server-11gR2-preinstall setting for fs.aio-max-nr is 1048576
fs.aio-max-nr = 1048576

# oracle-rdbms-server-11gR2-preinstall setting for net.ipv4.ip_local_port_range is 9000 65500
net.ipv4.ip_local_port_range = 9000 65500
EOF

# Limits setting
echo "Limits settings"
memlock=$[$numberOfHugePages*$hugepagesize]
file="$limits_conf"

cat > "$file" << EOF


# Labs settings for oracle
# Limits setting
oracle soft memlock $memlock
oracle hard memlock $memlock

# Open file descriptors for oracle user
oracle hard nofile $processinput

# oracle-rdbms-server-11gR2-preinstall setting for nproc soft limit is 16384
# refer orabug15971421 for more info.
oracle   soft   nproc    16384

# oracle-rdbms-server-11gR2-preinstall setting for nproc hard limit is 16384
oracle   hard   nproc    16384

# oracle-rdbms-server-11gR2-preinstall setting for stack soft limit is 10240KB
oracle   soft   stack    10240

# oracle-rdbms-server-11gR2-preinstall setting for stack hard limit is 32768KB
oracle   hard   stack    32768
EOF


function disableTuned {
    # Disabling transparent hugepages
    echo "Disabling transparent hugepages"
    service tuned stop
    chkconfig tuned off
}
function setGrub {
    IFS== arr=($1) IFS=
    key=${arr[0]}
    value=${arr[1]}
    if [ $( grep -aEs $1 /proc/cmdline -q; echo $? ) -ne '0' ]; then

        file="/etc/default/grub"
        if [ $( grep -aEs $key $file -q; echo $? ) -eq '0' ]; then
            sed -i 's/\s'$key'=[^"\s\t]*\s/ /g' $file
            sed -i 's/\s'$key'=[^"\s\t]*"/"/g' $file
        fi
        sed -i '/^\s*GRUB_CMDLINE_LINUX/ s/"$/ '$1'"/' $file
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
		#grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
}

# Add HugePage allocation as a boot option.
disableTuned
setGrub "hugepages=$numberOfHugePages"
setGrub "transparent_hugepage=never"
setGrub "numa=off"

sysctl --system
sysctl -p




