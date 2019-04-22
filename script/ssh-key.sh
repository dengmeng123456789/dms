ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa
cat  ~/.ssh/id_rsa.pub  >  /root/.ssh/authorized_keys
#+++++++++++++++++++++++获取在线的IP用户++++++++++++++++++++++++++++++++++++++
#获取和本机相同的网段的IP
Network=`ifconfig  ens33 |awk '/broadcast/{print $2}' | awk -F '.'  '{print $1"."$2"."$3}'`
files=/root/sh/IP.txt
[ -f $files ] || touch $files
#写入空值到文件保证文件字符为0by
echo " "  >  $files
#=================================获取在线IP========================
for  p  in  `seq 10  15`						
do
        ping -c 3 "$Network".$p  > /dev/null
        if [ $? -eq 0 ];then
                #这步保证的是文件没有重复的IP  100%为存在的IP
                echo  "$Network".$p  >>  $files
        fi
done
#=====================================================================
MyIp=`ifconfig  ens33 |awk '/broadcast/{print $2}'`
IP=`cat /root/sh/IP.txt |grep  -v $MyIp |xargs`
for  i in  ${IP[@]}
do
        #将本机的公钥发送给对方主机，从而scp时不要输入密码（免密登入）
        ssh-copy-id    root@$i
        #登入到对方的主机，让其产生公钥
        ssh root@$i  'echo |ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa'
        #将对方主机的公钥发送到本机的host这个文件，host其实就是一个中转站，因为每次scp传输过来的数据都会覆盖写入到host文件
        scp   -r   $i:/root/.ssh/id_rsa.pub    /root/.ssh/host

        #将host文件内容追加到authorized_keys文件中
        cat  /root/.ssh/host  >> /root/.ssh/authorized_keys
done
#=====================当每个IP的公钥都在authorized_keys时再分发到各IPauthorized_keys文件=================
for  io in ${IP[@]}
do
        #将本地的authorized_keys  复制到对方主机authorized_keys(授权密钥)
        scp -r /root/.ssh/authorized_keys   $io:/root/.ssh/authorized_keys
done
