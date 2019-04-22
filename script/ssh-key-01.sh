[ -x /usr/bin/expect ]  || yum install expect  $ > /dev/null
ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa 
cat  ~/.ssh/id_rsa.pub  >  /root/.ssh/authorized_keys
Network=`ifconfig  ens33 |awk '/broadcast/{print $2}' | awk -F '.'  '{print $1"."$2"."$3}'`
files=/root/sh/IP.txt
[ -f $files ] || touch $files
echo " "  >  $files
for  p  in  `seq 11  12`						
do
        ping -c 3 "$Network".$p  > /dev/null
        if [ $? -eq 0 ];then
                echo  "$Network".$p  >>  $files
        fi
done
MyIp=`ifconfig  ens33 |awk '/broadcast/{print $2}'`
IP=`cat /root/sh/IP.txt |grep  -v $MyIp |xargs`
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
	ssh root@$i  'echo |ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa'
        scp   -r   $i:/root/.ssh/id_rsa.pub    /root/.ssh/host
        cat  /root/.ssh/host  >> /root/.ssh/authorized_keys
done
for  io in ${IP[@]}
do
        scp -r /root/.ssh/authorized_keys   $io:/root/.ssh/authorized_keys
done
