#!/bin/bash
zabbix_repo='/etc/yum.repos.d/'
Mysql='mariadb mariadb-server'
Mysql_passwd='root'
zabbix_server='/etc/zabbix/zabbix_server.conf'
zabbix_agentd='/etc/zabbix/zabbix_agentd.conf'
IP=$(ifconfig  ens33 |awk '/broadcast/{print $2}')
Home=`cd /root`

#cd  $zabbix_repo;[ -d  repos ] || mkdir  repos;mv  *.repo  repos
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum  install  -y  epel-release
yum clean  all;yum repolist;yum makecache
systemctl status firewalld  |grep  running   &&   systemctl stop  firewalld; systemctl disable firewalld

function  zabbix(){
	[ -e   $zabbix_repo/zabbix.repo  ]  || rpm  -ivh https://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm
#rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
	yum clean  all;yum repolist;yum makecache
	zabbix_package=(zabbix-agent  zabbix-get zabbix-release zabbix-sender  zabbix-server-mysql  zabbix-web   zabbix-web-mysql)
	for  package  in  ${zabbix_package[@]}
	do
        	rpm   -q  $package ||   yum install  -y  $package
	done

[  -f $zabbix_server.bak ]  ||  cp  -a  $zabbix_server{,.bak}
[  -f $zabbix_zabbix_agentd.bak ]  ||  cp  -a  $zabbix_agentd{,.bak}
sed  -i  -e  "97{s/Server=127.0.0.1/Server=$IP/g}"    -i   -e   "138{s/ServerActive=127.0.0.1/ServerActive=$IP/g}"    $zabbix_agentd
sed   -i   -e  "12{s/#//g}"   -i  -e "65{s/#//g}"    -i -e  "19i\SourceIP=$IP"  -i -e "126i\DBPassword=$Mysql_passwd" sed  -i  -e  "141{s/#//g}"  $zabbix_server
	systemctl  restart ${zabbix_package[0]} zabbix-server.service;systemctl enable  zabbix-server.service  ${zabbix_package[0]}
}

#******************************mysql***************************
function Maridb(){
MYSQL='mariadb-server mariadb'
        rpm -q $MYSQL && echo "$MYSQL已经安装" || yum install -y $MYSQL
        systemctl status  mariadb |grep  dead  &&   systemctl restart mariadb   ||echo "服务已经启动"
	systemctl enable  mariadb
[ -x /usr/bin/expect ] || yum install expect -y   &>/dev/null
/usr/bin/expect <<-EOF
spawn mysql_secure_installation
expect {
        "Enter current password for root" {send "\n";exp_continue}
        "Set root password?" {send "n\n";exp_continue}
        "Remove anonymous users?" {send "y\n";exp_continue}
        "Disallow root login remotely?" {send "y\n";exp_continue}
        "Remove test database and access to it? " {send "y\n";exp_continue}
        "Reload privilege tables now?"  {send "y\n"}
	
}
expect eof
EOF
mysql -e  "create database zabbix character set utf8 collate utf8_bin;show databases"
mysql  -e  "grant  all   on  zabbix.*  to  zabbix@'localhost'  identified  by '"$Mysql_passwd"';flush  privileges"
mysql  -e  "grant  all   on  zabbix.*  to  zabbix@'%'  identified  by '"$Mysql_passwd"';flush  privileges;select user,host,password  from  mysql.user;"
#mysql  -e  "grant  all  on  *.*  to  root@'%'  identified  by  '"$Mysql_passwd"';flush   privileges;" > /dev/null
#mysql   -e  "update  mysql.user  set  password=password('"$Mysql_passwd"')  where  user='root'  and  host='localhost';flush  privileges;" 
zcat  /usr/share/doc/zabbix-server-mysql*/create.sql.gz |mysql -uzabbix  -p"$Mysql_passwd"  zabbix
#优化
echo "[mysqld]
server-id=$IP
log-bin=master-bin
innodb_buffer_pool_size = 256M  
max_connections = 2000 
skip_name_resolv= ON
log_slave_updates=1"  > /etc/my.cnf.d/master.cnf 
}

function  php_time(){
sed   -i  "878i\date.timezone = Asia/Shanghai" /etc/php.ini
systemctl  restart  httpd
}

All=(zabbix Maridb php_time)
for  packages in  ${All[@]}
do
	$Home;$packages
done
echo "使用浏览器访问$IP/zabbix"








	



