#!/bin/bash
Network=`ifconfig  ens33 |awk '/broadcast/{print $2}' | awk -F '.'  '{print $1"."$2"."$3}'`
files=/root/sh/IP.txt
[ -f $files ]  && echo "存在" || touch $files
#写入空值到文件保证文件字符为0by
echo " "  >  $files
for i  in  `seq 1  15`
do
( 	ping -c 3 "$Network".$i 
	if [ $? -eq 0 ];then
		#这步保证的是文件没有重复的IP  100%为存在的IP
		echo  "$Network".$i  >>  $files
#	else 
#		#将不存在IP从$file 剔除
#		grep   "$Network".$i  $files
#		echo  "$Network".$i  "不在线"
	fi
)&
done
