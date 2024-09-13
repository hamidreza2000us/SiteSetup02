echo -e "Plase Copy and Paste (just) the WWN of new LUNs you are willing to format"
echo -e "Then press ctrl+d"
WWNInput=$(</dev/stdin)
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
Color_Off='\033[0m'       # Text Reset
while read line
do
   diskCheck=true
   msg=''
   #echo "Checking disk: |${line}|"
   #echo "Full information about the disk is as below:"
   diskInfo=$(upadmin show vlun | grep "${line}")
   LUNName=$( echo ${diskInfo} | awk '{print $3}' )
   #partprobe -d -s /dev/disk/by-id/scsi-3"${line}"
   parted  /dev/disk/by-id/scsi-3"${line}" print 1 &> /dev/null
   if [ $? -eq 0 ] ; then msg+="\tDisk is already partitioned\n" ; diskCheck=false ; fi
   sleep 1
   oracleasm querydisk /dev/disk/by-id/scsi-3"${line}" &> /dev/null
   if [ $? -eq 0 ] ; then msg+="\tDisk belongs to Oracle ASM\n" ; diskCheck=false ; fi
   diskID="/dev/disk/by-id/scsi-3${line}-part1"
   oracleasm  querydisk "$diskID" &> /dev/null
   if [ $? -eq 0 ] ; then msg+="\tDisk belongs to Oracle ASM\n" ; diskCheck=false ; fi
   fuser -m  /dev/disk/by-id/scsi-3"${line}" &> /dev/null
   if [ $? -eq 0 ] ; then msg+="\tDisk is already in use\n" ; diskCheck=false ; fi
   fuser -m "$diskID" &> /dev/null
   if [ $? -eq 0 ] ; then msg+="\tDisk is already in use\n" ; diskCheck=false ; fi
   if [ ${diskCheck} == true ]
   then
     echo -e "${BIGreen}Disk ${LUNName} with ID ${line} is ready to use${Color_Off}"
     #parted -s -a optimal /dev/disk/by-id/scsi-3"${line}" mklabel gpt mkpart primary  2048 100%
     #oracleasm createdisk  ${LUNName} ${diskID}
   else
     echo -e "${BIRed}Disk ${LUNName} with ID ${line} is NOT ready to use: ${Color_Off}"
   fi
     echo -e "${msg}"
     echo -n ""
     echo -n ""
done <<< "${WWNInput}"
