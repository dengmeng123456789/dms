#多机/root/sh/IP.txt互信可将各机器的公钥
#先产生本机的公钥放到authorized_keys文件中
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
#==============================================================================================


MYSQL='mariadb-server mariadb'
        rpm -q $MYSQL && echo "$MYSQL已经安装" || yum install -y $MYSQL
        systemctl status  mariadb |grep  dead  &&   systemctl restart mariadb   ||echo "服务已经启动"
	systemctl enable  mariadb
#(2)【配置root数据设置】、【主从设置】
	echo "===================友情提示   设置完root数据库用户名直接回车========================"
        read -p "为数据库超级管理设置密码"   PASS
        #【root数据设置】
mysql  -e  "grant  all  on  *.*  to  root@'%'  identified  by  \"$PASS\";flush   privileges;" > /dev/null
 mysql   -e  "update  mysql.user  set  password=password(\"$PASS\")  where  user='root'  and  host='localhost';flush  privileges;"  
mysql  -uroot  -p$PASS  -e  'show  databases;select   user,host,password  from  mysql.user;'
#【主从设置】
Host=`ifconfig  ens33 |awk '/broadcast/{print $2}' | awk -F '.'  '{print $4}'`
echo "[mysqld]
server-id=$Host
log-bin=master-bin
skip_name_resolv=1
log_slave_updates=1"  > /etc/my.cnf.d/master.cnf 
        systemctl restart   mariadb
	echo  "===================友情提示  自动创建数据库用户名——>rep========================"
	sleep  3s
        mysql -uroot -p$PASS  -e  "grant  replication slave  on  *.*  to  rep@'%'  identified by 'rep';flush privileges;reset master;show master status"

#(3) 【设置将slave.sh传输到slave机器】
[ -d /mysql_master ]  || mkdir -p /mysql_master
cp -a   /root/sh/slave.sh /mysql_master
read -p "输入多机器IP地址：" -a  IP
for IPs  in ${IP[@]} 
do       
       ssh root@$IPs  'mkdir /mysql_slave'
       scp -r  /mysql_master/slave.sh  root@$IPs:/mysql_slave
       ssh root@$IPs   'sh  /mysql_slave/slave.sh'
done
for  io in ${IP[@]}
do
 #将本地的authorized_keys  复制到对方主机authorized_keys(授权密钥)
  scp -r /root/.ssh/authorized_keys   $io:/root/.ssh/authorized_keys
done


