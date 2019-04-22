#!/bin/bash
Root_Home=`cd ~`
Rely_on_package='epel-release openssl-devel gcc-c++  zlib-devel pcre-devel  wget vim-enhanced   make cmake  ncurses-devel libaio bison perl-Data-Dumper libxml2-devel'
#boost boost-doc boost-devel 
for package  in  ${Rely_on_package[@]}
do
	rpm -q  $package || yum install -y $package   #  >/dev/null 2>&1   默认为1  1>>/dev/null 2>&1 
done
function  prce(){
	PATH_pcre='/usr/local/pcre';cd $PATH_pcre
	if [ $? != 1 ];then
		wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.40.tar.gz
		tar -zvxf pcre-8.40.tar.gz;cd pcre-8.40/
		./configure --prefix=$PATH_pcre
		make  && make install
	fi
}


function  Nginx(){
	PATH_Nginx='/usr/local/nginx';cd $PATH_Nginx  #正常访问目录状态值为0
	if [ $? != 1 ];then	
		wget  http://nginx.org/download/nginx-1.10.3.tar.gz
		tar -zvxf nginx-1.10.3.tar.gz
		cd nginx-1.10.3/
		useradd  nginx  -M  -s /sbin/nologin
		./configure  --prefix=$PATH_Nginx  --user=nginx  --group=nginx --with-http_stub_status_module --with-http_ssl_module  --with-file-aio 
#各模块简介
#-with-file-aio   aio的优点就是能够同时提交多个io请求给内核，然后直接由内核的io调度算法去处理这些请求(directio)，这样的话，内核就有可能执行一些合并，优化,此模块要求内核保持在2.6.22以上
#--with-http_realip_module 此模块支持显示真实来源IP地址，主要用于NGINX做前端负载均衡服务器使用。
		make && make install
		ln -s  /usr/local/nginx/sbin/nginx  /usr/bin/nginx
	fi
}

function  Mysql(){
	PATH_mysql='/usr/local/mysql';cd $PATH_mysql
	wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.15.tar.gz
	tar -zxf mysql-8.0.15.tar.gz;cd  mysql-8.0.15
cmake \
-DCMAKE_INSTALL_PREFIX=$PATH_mysql     
-DMYSQL_DATADIR=$PATH_mysql/data    
-DSYSCONFDIR=/etc 
-DMYSQL_USER=mysql 
-DWITH_MYISAM_STORAGE_ENGINE=1          
-DWITH_INNOBASE_STORAGE_ENGINE=1      
-DWITH_MEMORY_STORAGE_ENGINE=1           
-DWITH_READLINE=1    
-DMYSQL_UNIX_ADDR=/tmp/mysqld.sock 
-DMYSQL_TCP_PORT=3306    
-DENABLED_LOCAL_INFILE=1
-DWITH_PARTITION_STORAGE_ENGINE=1   
-DEXTRA_CHARSETS=all 
-DDEFAULT_CHARSET=utf8 
-DDEFAULT_COLLATION=utf8_general_ci
make &&make install
	fi
}

function  PHP(){
	PATH_PHP='/usr/local/php7';cd $PATH_PHP 
	if [ $? != 1 ];then
		wget http://hk1.php.net/get/php-7.0.32.tar.gz/from/this/mirror
		tar -zvxf mirror ;cd php-7.0.32/
		./configure  --prefix=$PATH_PHP  --enable-fpm --with-pdo-mysql=mysqlnd  --enable-mysqlnd 
		make && make install
		ln -s  /usr/local/php7/sbin/php-fpm   /usr/bin/php-fpm
		cd /usr/local/php7/etc/;[ -f   php-fpm.conf ] || mv php-fpm.conf.default  php-fpm.conf
		cd php-fpm.d/;[ -f  www.conf ] || mv www.conf.default  www.conf
		$Root_Home
	fi
}

function echos(){
	echo '
	nginx的常用命令
	./nginx         启动
	./nginx -s stop 停止
	./nginx -t      检查nginx.conf脚本是否正常
	./nginx -s  reload 重新加'
}

ALLS='prce  Nginx Mysql  PHP echos '
for ands  in  ${ALLS[@]} 
do
     $Root_Home;$ands
done

