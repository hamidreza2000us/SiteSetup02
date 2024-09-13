mkdir tzfolder
cd tzfolder
#wget http://ftp.riken.jp/Linux/cern/centos/7/os/Sources/SPackages/tzdata-2020a-1.el7.src.rpm
rpm2cpio tzdata-2020a-1.el7.src.rpm | cpio -idmv
tar -xvf tzdata2020a.tar.gz
cp asia asia.back
#modify the time in the asia file
zic asia
#zdump -v /etc/localtime
#date -s "21 Mar 2021 23:59:50"
#watch -n1 date

