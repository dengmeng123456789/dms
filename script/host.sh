wangke=`ifconfig  |egrep  "e" |head -n 1 |awk   -F ":" '{print $1}'|head  -n 1`
Network=`ifconfig  $wangke |awk '/broadcast/{print $2}' | awk -F '.'  '{print $1"."$2"."$3}'`
files=/root/Host_IP.txt
[ -f $files ] || touch $files
echo " "  >  $files
read -p  "IP地址的启始范围为：" a
read -p  "IP地址结束的范围为：" b
for  p  in  `seq $a $b`
do
        ping -c 3 "$Network".$p  > /dev/null
        if [ $? -eq 0 ];then
		echo  "$Network".$p  >>  $files
	fi
done
HOSTS=`cat /root/IP.txt |xargs`
Host_File="/etc/hosts"
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >  $Host_File
for  i in  ${HOSTS[@]}
do
	HOST_NAMES=`ssh root@$i  hostname`
	echo  "$i  $HOST_NAMES" >> $Host_File
done
#这个是已经做了ssh密码登入
for IP  in  ${HOSTS[@]}
do
	scp -r $Host_File  root@$IP:$Host_File
done
[ -f $files ]  && rm -rf $files


