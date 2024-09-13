#/bin/bash
allLenght=80
allLenght=$[ $allLenght -  $[$allLenght % 2] ]

msg1='Welcome'
msg2='All connections are monitored and recorded'
msg3='Disconnect IMMEDIATELY if you are not an authorized user!'

printLine() {
line='';
for i in $(seq $allLenght)
  do  line="$line#"
done
echo "$line"
}

printMsg() {
line='#'
msg="$1"
spaces=$[($allLenght-2-${#msg})/2]
for i in $(seq $[($allLenght-2-${#msg})/2])
do
  line+=' '
done
line+="$msg"
for i in $(seq $[($allLenght-2-${#msg})/2])
do
  line+=' '
done
[[ $[ ${#msg} % 2] == 1 ]] && line+=' '
echo "$line#"
}


linebreak () {
unset myline
linenumber=0;
line='';
msg="${1} "
for i in ${msg}
do
   if [[ $[${#line}+${#i}] -gt $[${allLenght}-4] ]]
   then
        lastval="${i}"
        printMsg "${line}"
        line="${lastval} " ;
   else
        line+="${i} " ;
   fi
done
printMsg "${line}"
}

printLine

#for i in "${@}"
#do
#    linebreak "${i}"
#done

linebreak "$msg1"
linebreak "$msg2"
linebreak "$msg3"
printLine
echo " "
echo " "
