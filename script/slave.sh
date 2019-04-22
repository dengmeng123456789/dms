#!/bin/bash
MYSQL='mariadb-server mariadb'
        rpm -q $MYSQL && echo "$MYSQL已经安装" || yum install -y $MYSQL
        systemctl status  mariadb |grep  dead  &&   systemctl restart mariadb   ||echo "服务已经启动"
	systemctl  enable mariadb 
#cat > /etc/my.cnf.d/master.cnf <<EOF
#[mysqld]
#server-id=12
#log-bin=master-bin
#skip_name_resolv=1
#log_slave_updates=1
#EOF
host=`ifconfig  ens33 |awk '/broadcast/{print $2}' | awk -F '.'  '{print $4}'`
echo "[mysqld]
server-id=$host
#log-bin=slave-bin
skip_name_resolv=1
log_slave_updates=1"   >  /etc/my.cnf.d/slave.cnf  
#read -p  "master用户" User
#read -p  "master密码" Pass
mysql  -urep -prep  -h 192.168.11.11 -e 'status;'
systemctl  restart   mariadb
echo  "++++++++++++++++=========  从数据库目前没有设置密码可直接回车  ===============+++++++++++++++++++++++++++"
mysql -uroot -p   -e "
CHANGE MASTER TO
  MASTER_HOST='192.168.11.11',
  MASTER_USER='rep',
  MASTER_PASSWORD='rep',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='master-bin.000001',
  MASTER_LOG_POS=245,
  MASTER_CONNECT_RETRY=10;"
mysql  -uroot -p -e "reset slave;start slave;show slave status\G;"

