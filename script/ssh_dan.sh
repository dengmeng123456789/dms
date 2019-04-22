#!/bin/bash
#########################
#			#
#	单机互信	#
#			#
#########################
[ -x /usr/bin/expect ]   || yum install -y expect & > /dev/null
ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa
cat  ~/.ssh/id_rsa.pub  >  /root/.ssh/authorized_keys
#+++++++++++++++++++++++获取在线的IP用户++++++++++++++++++++++++++++++++++++++
#获取和本机相同的网段的IP
Network=`ifconfig  ens33 |awk '/broadcast/{print $2}' | awk -F '.'  '{print $1"."$2"."$3}'`
files=/root/sh/IP.txt
[ -f $files ] || touch $files
#写入空值到文件保证文件字符为0by
echo " "  >  $files
for  p  in  `seq 10  15`
do
        ping -c 3 "$Network".$p  > /dev/null
        if [ $? -eq 0 ];then
                #这步保证的是文件没有重复的IP  100%为存在的IP
                echo  "$Network".$p  >>  $files
        fi
done
MyIp=`ifconfig  ens33 |awk '/broadcast/{print $2}'`
IP=`cat /root/sh/IP.txt |grep  -v $MyIp |xargs`
for  i in  ${IP[@]}
do
        #将本机的公钥发送给对方主机，从而scp时不要输入密码（免密登入）
/usr/bin/expect <<-EOF
spawn ssh-copy-id    root@$i
expect {
      "yes/no"  {send "yes\n";exp_continue}
      "password"  {send "root\n"}
    }
    expect eof
EOF
done
