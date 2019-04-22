#!/bin/bash
zabbix_repo='/etc/yum.repos.d/'
cd  $zabbix_repo;[ -d repos ]mkdir  repos;mv  *.repo   repos
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean  all;yum repolist;yum makecache
Rely_on_package=(epel-release)
for package  in  ${Rely_on_package[@]}
do
        rpm -q  $package || yum install -y $package   #  >/dev/null 2>&1   默认为1  1>>/dev/null 2>&1
done

function  Nginx(){
	rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
	rpm -q nginx  || yum install  -y nginx
	systemctl  disable httpd > /dev/null 2>&1;systemctl  stop  httpd  > /dev/null 2>&1
	systemctl status nginx.service  |grep  dead  &&   systemctl restart  nginx.service || echo "服务已经启动";systemctl enable nginx.service
}
function Mysql(){
	rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
 	Mysql_package=(mysql   mysql-server  mysql-libs mysql-server)
	rpm -q mysql 
		if [ $? != 0 ];then	
			for  package  in  ${Mysql_package[@]}
			do
				rpm  -q  $package || yum install  -y $package
			done
		fi
	systemctl status nginx.service  |grep  dead  &&   systemctl restart  nginx.service || echo "服务已经启动"
	systemctl enable mysql.service
}

function  mariadb(){
	 rpm -q mariadb || yum install -y  mariadb-server  mariadb
	 #数据库初始化
	systemctl status  mariadb |grep  dead  &&   systemctl restart mariadb   || echo "服务已经启动"
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

}
	

function  PHP(){
	Rely_on_package=(epel-release php-gd php-imap php-ldap php-odbc php-pear php-xml php-xmlrpc php php-mysql php-fpm)
	for package  in  ${Rely_on_package[@]}
	do
	        rpm -q  $package || yum install -y $package # > /dev/null 2>&1
	done	
	systemctl restart  php-fpm
}

function Httpd(){
	rpm -q httpd  ||  yum   -y httpd
	systemctl  disable   nginx > /dev/null 2>&1
        systemctl   stop     nginx > /dev/null 2>&1
        systemctl  enable  httpd 
	systemctl  restart     httpd
	
}

function  helps(){
	help_txt='/root/help.txt'
	echo '#访问.php文件时会被加载而不是被下载。没有添加如下代码访问测试php时直接下载而不会在web页面看到php
	location / {
	   root   /usr/share/nginx/html;
           index  index.html index.htm index.php;
        }
	location ~ \.php$ {
           root           html;
           fastcgi_pass   127.0.0.1:9000;
           fastcgi_index  index.php;
           fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
           include        fastcgi_params;
       }' > $help_txt;echo  "查看文档$help_txt";sleep 5s
}
ALLS=(Nginx Mysql PHP helps)
for  package in  ${ALLS[@]}
do
	$package
done
