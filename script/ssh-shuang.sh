#!/bin/bash
[ -x /usr/bin/expect ]  || yum install expect  -y  
ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa 
cat  ~/.ssh/id_rsa.pub  >  /root/.ssh/authorized_keys
wangke=`ifconfig  |egrep  "e" |head -n 1 |awk   -F ":" '{print $1}'|head  -n 1`
Network=`ifconfig  $wangke |awk '/broadcast/{print $2}' | awk -F '.'  '{print $1"."$2"."$3}'`
files=/root/IP.txt
[ -f $files ] || touch $files
echo " "  >  $files
#只适用于局域网，保证同网段
read -p  "IP地址的启始范围为：" a
read -p  "IP地址结束的范围为：" b
#bs=`expr $b + 1`
for  p  in  `seq $a $b`						
do
        ping -c 3 "$Network".$p  > /dev/null
        if [ $? -eq 0 ];then
                echo  "$Network".$p  >>  $files
        fi
done
#计算机的访问过公钥不需要有本机可注释下面的代码(known_hosts文件)
#MyIp=`ifconfig  $wangke |awk '/broadcast/{print $2}'`
#IP=`cat /root/IP.txt |grep  -v $MyIp |xargs`
IP=`cat /root/IP.txt  |xargs`
for  i in  ${IP[@]}
do      
/usr/bin/expect <<-EOF
spawn ssh-copy-id    root@$i
expect {
      "yes/no"  {send "yes\n";exp_continue}
      "password"  {send "root\n"}
    }
    expect eof
EOF
	#将对方的公钥传到本地
	ssh root@$i  'echo |ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa'
	#scp 复制过去的文件会覆盖之前的内容，为数据提供了更好的方便，host就是个中转站而已
        scp   -r   $i:/root/.ssh/id_rsa.pub    /root/.ssh/host
        cat  /root/.ssh/host  >> /root/.ssh/authorized_keys
done
	#将上线的主机公钥全部传给各个主机，让其全部免密登入
for  io in ${IP[@]}
do
        scp -r /root/.ssh/authorized_keys   $io:/root/.ssh/authorized_keys
done
#删除多余文件，如果需要可以查看获取的IP地，址注释掉下面代码取消删除
[ -f $files ]  &&   rm  -rf   $files
