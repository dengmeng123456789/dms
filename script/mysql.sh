#!bin/bash
#多机互信可将各机器的公钥
#先产生本机的公钥放到authorized_keys文件中
ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa 
cat  ~/.ssh/id_rsa.pub  >  /root/.ssh/authorized_keys
#read -p "输入多机器IP地址：" -a  IP
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
	ssh-copy-id    root@$i
	#登入到对方的主机，让其产生公钥
	ssh root@$i  'echo |ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa'
	#将对方主机的公钥发送到本机的host这个文件，host其实就是一个中转站，因为每次scp传输过来的数据都会覆盖写入到host文件
	scp   -r   $i:/root/.ssh/id_rsa.pub    /root/.ssh/host
	
	#将host文件内容追加到authorized_keys文件中
	cat  /root/.ssh/host  >> /root/.ssh/authorized_keys
done
	#将本地的authorized_keys  复制到对方主机authorized_keys(授权密钥)
	for  io in ${IP[@]}
	do
        scp -r /root/.ssh/authorized_keys   $io:/root/.ssh/authorized_keys
	done
#3:（nfs是为了可以slave端有slave可执行脚本） ————————目前已解决
#soft='nfs-utils rpcbind'
#        rpm -q $soft && echo "$soft已经安装" || yum install -y $soft
#        systemctl status  rpcbind |grep  dead  &&   systemctl restart rpcbind   ||echo ">服务已经启动"
#        systemctl status  nfs |grep  dead  &&   systemctl restart nfs || echo ">服务已经>启动"
#        systemctl  enable rpcbind  nfs
#        read  -p  "你要共享的路径：" lj
#                [ -d  $lj ]  && echo "已经有此目录" || mkdir -p  $lj
#                echo   "${lj}  *(rw,no_root_squash)" >> /etc/exports
#        exportfs  -arv
#        showmount  -e localhost
	#+++++++++++++++++++++++++++++++++++需要改动+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#ssh  root@192.168.11.12  'yum install -y  nfs-utils rpcbind; systemctl restart rpcbind  nfs ;systemctl enable  rpcbind  nfs ;mkdir -p  /gua_nfs;mount.nfs  192.168.11.11:/nfs  /gua_nfs'


# 保证master配置OK   master 数据库OK   创建一个主从数据库    保证log-bin文件名为000001 
#(1)保证服务安装启动
MYSQL='mariadb-server mariadb'
        rpm -q $MYSQL echo "$MYSQL已经安装" || yum install -y $MYSQL
        systemctl status  mariadb |grep  dead  &&   systemctl restart mariadb   ||echo ">服务已经启动"

#(2)配置root数据设置、主从设置
        read -p "为数据库超级管理设置密码"   -s  PASS
        #root数据设置
        mysql -e  "grant  all on  *.*  to  root@'%'  identified by \"$PASS\";flush privileges;"   & >2
        mysql  -e "update  mysql.user set password=password(\"$PASS\") where   user='root' and  host='localhost';select user,host,password from mysql.user;flush privileges;"  > /dev/null   & >2 
        #主从设置
#+==================================需要 修改 ======================
cat > /etc/my.cnf.d/master.cnf <<EOF
[mysqld]
server-id=11
log-bin=master-bin
skip_name_resolv=1
log_slave_updates=1
EOF
        systemctl restart   mariadb
	read -p "输入你要搭建主从服务器从用户名"  NAMES
	read -p "输入你要搭建主从服务器从密码"  -s PASSWORD
        mysql -uroot -p  -e  "grant  replication slave  on  *.*  to  $NAMES@'%'  identified by \"$PASSWORD\";flush privileges;reset master;show master status"

	
	

	
#2: 保证slave配置OK    告诉slave的主人是谁写入配置文件 并且开启服务
#!/bin/bash
MYSQL='mariadb-server mariadb'
        rpm -q $MYSQL echo "$MYSQL已经安装" || yum install -y $MYSQL
        systemctl status  mariadb |grep  dead  &&   systemctl restart mariadb   ||echo ">服务已经启动"
cat > /etc/my.cnf.d/master.cnf <<EOF
[mysqld]
server-id=11
log-bin=master-bin
skip_name_resolv=1
log_slave_updates=1
EOF

scp  -r /nfs/slave.sh  192.168.11.12/root
ssh root@192.168.11.12 'sh /root/slave.sh'





