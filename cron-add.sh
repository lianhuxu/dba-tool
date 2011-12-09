#!/bin/bash
#  How to :
#     cron-add.sh -h host.file -c cron.file
#  Description:
#     Add some crontab job to lots of host in a batch  mode.
#     I did this a lot, so a auto script comes.
#
#     if the jobs exsit on the host, will not add again
#  Sample:
#     $cat slave.host
#      192.169.1.110
#      192.169.1.112
#      192.169.1.115
#     $cat new.cron.job
#      * * * * * /opt/jobs/bin/timeupdate.sh > /tmp/t.log 2>&1 
#      * * * * * /opt/jobs/bin/otherjob.sh > /tmp/o.log 2>&1 
#     $cron-add.sh -f slave.host -c new.cron.job
#
hostfile=""
cronfile=""
sshoption=" -o BatchMode=yes "

while getopts ":f:c:h" opt; do
case $opt in
    f)
      hostfile=$OPTARG
      ;;
    c)
      cronfile=$OPTARG
      ;;
    h)
      echo "How to use: $0 [-f host.file] [-c cron.file]"
      exit 0
      ;;
    ?)
      echo "How to use: $0 [-f host.file] [-c cron.file]" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done 
for host in `cat $hostfile`
do
   echo "working on $host"
   ssh $sshoption $host "crontab -l" > ./log/tmp.$host.cron.ori
   while read line
   do
       tmpcron=`echo "$line"|awk '{print $6}'`
       exist=`grep "$tmpcron" ./log/tmp.$host.cron.ori|wc -l`
       if [ $exist -eq 0 ];then
          #add new cron
          echo "  On $host add $line"
          echo "$line" >> ./log/tmp.$host.cron.ori
       fi
   done < $cronfile
   scp $sshoption ./log/tmp.$host.cron.ori $host:/tmp/tmp.$host.cron >> scp.log 2>&1
   ssh $sshoption $host "crontab /tmp/tmp.$host.cron"
done
