#!/bin/bash

mkdir -p /var/Decomm
rm /var/Decomm/`hostname`.txt
LOG_FILE="/var/Decomm/`hostname`.txt"
hponcfg -w /var/tmp/ilo.cfg
ILOIP=`cat /var/tmp/ilo.cfg | grep -i "<ip_address" | awk -F '"' '{print $2}'`
printf $ILOIP > /tmp/iloip.txt
clear
function CSV_Check(){
 echo -e "Hostname\t |`hostname`"
 echo -e "Vendor\t |`dmidecode -s system-manufacturer`"
 echo -e "Model Number\t |`dmidecode -s system-product-name`"
 echo -e "Serial Number\t |`dmidecode -s system-serial-number`"
 echo -e "Primary IP Address\t |`ifconfig | grep 'inet addr' | awk -F: '{print $1,$2}' | awk ' NR==1 {print $3}'`"
 #This below Output do not display total Physical RAM,but shows RAM Used OS
 echo -e "Memory\t | `cat /proc/meminfo | grep -i memtotal | awk '{printf ("%f GB\n",($2/(1024*1024)))}'`"
 echo -e "Domain\t |`dnsdomainname`"
 echo -e "OS\t | `cat /etc/*release | awk 'NR==4'`"
 echo "|"
 #Newly Included - Arpan
 if [ -e /opt/tivoli/tsm/client/ba/bin ] ; then
        echo -e "TSM Server \t |`cat /opt/tivoli/tsm/client/ba/bin/dsm.opt | awk '{print $2}' | grep -i tsm`"
 else
        echo -e "TSM \t |No"
 fi
 if [ -e /home/oracle  ] ; then
        echo -e "Oracle \t |Yes"
 else
        echo -e "Oracle \t |No"
 fi
 if [ -e /etc/init.d/avagent ]; then
	echo -e "Avamar \t |`/etc/init.d/avagent status | grep DPN | awk '{print $6}'`"
 else 
	echo -e "Avamar \t | No"
 fi
 if [ -e /etc/init.d/mysqld ]; then
	echo -e "MySQL \t |Yes"
 else 
	echo -e "MySQL \t |No"
 fi
 echo "|"
 echo -e "All the IP Configurations:"
 if_array=(`ifconfig | awk '{print $1}' | egrep 'bond|eth'`)
  for x in ${if_array[@]}; do {
  echo -e "$x \n `ifconfig $x | egrep 'HWaddr|inet' | awk '{print $2,$3,$4,$5}'`";
   
  }
  done
 
 echo "|"
 echo -e "NAS Mounts  | \n `mount -t nfs | cut -f1 -d " "`"
 echo "|"
}

function luninfo() {
 echo -e "\n\nHBA Adapter Information :"
 if [ -d "/sys/class/fc_host" ] ; then
	cd /sys/class/fc_host
	ls -w1 | while read i ; do
	if [ -f "$i/port_name" ] ; then
		echo -n "WWN: "
		cat $i/port_name
	fi
	done
 elif [ -d "/proc/scsi/qla2xxx" ] ; then
	cd /proc/scsi/qla2xxx
    ls -w1 | while read i ; do
	if [ -f "$i" ] ; then
		echo -n "wwn: "
		grep -E "scsi-qla.-adapter-port" $i|cut -d= -f2|cut -d\; -f1
	fi
	done
 else
    echo -e "\n\nHBA Adapter Information : Not Found"
 fi
}

function fioinfo() {
echo "|"
if [ `fio-status 2>/dev/null -ne 0` ]; then
 echo -e "\n\nFusion Adapter Information : | `df -hP | grep fio 2>/dev/null`"
 fio-status 2>/dev/null
else
 echo "Fusion Adapter is not present"
fi
}
main(){
	
	CSV_Check 2>&1 | tee -a $LOG_FILE
	luninfo 2>&1 | tee -a  $LOG_FILE
	fioinfo 2>&1 | tee -a  $LOG_FILE
}

main


	
