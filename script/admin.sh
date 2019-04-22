#!/bin/bash
_MENU(){
echo  '-------------admin   menu-------------------
1 :	install   NFS
2 :	install   Vsftpd
3 :	install   Samba
4 :     install   httpd
5 :	install	  DHCP
6 :	install   PXE
7 :	install   DNS
8 :	Stop  Firewalld  and  Selinux
9 :	Configuration   Local  Yum
10:	Add   	Users
11:     exit
------------------------------------------'
}
_NFS(){
soft='nfs-utils rpcbind'
	rpm -q $soft && echo "$soft已经安装" || yum install -y $soft
	systemctl status  rpcbind |grep  dead  &&   systemctl restart rpcbind   ||echo "服务已经启动"
	systemctl status  nfs |grep  dead  &&   systemctl restart nfs || echo ">服务已经启动"
	systemctl  enable rpcbind  nfs 
	read  -p  "你要共享的路径：" lj
		[ -d  $lj ]  && echo "已经有此目录" || mkdir -p  $lj 
		echo   "${lj}  *(rw,no_root_squash)" >> /etc/exports
	exportfs  -arv
	showmount  -e localhost
#	read  -p  "你要挂载的路径目录：" mounts
#		[ -d  ${mounts} ]   &&  echo "目录存在" ||   mkdir $mounts
#	IP=$(ifconfig  ens33 |awk '/broadcast/{print $2}')	
#	mount.nfs ${IP}:${lj}  $mounts
#	df -h

}	
_Vsftpd(){
vsftpd='vsftpd lftp ftp'
	rpm -q $vsftpd && echo "$vsftpd已经安装" || yum install -y $vsftpd
        systemctl status vsftpd  |grep  dead  &&   systemctl restart vsftpd   || echo "服务已经启动"
	systemctl  enable vsftpd 
        cp /etc/vsftpd/vsftpd.conf{,.bak}
	read	-p "是否允许匿名拥有权限 1:启动  2：不启用" num_a
		if  [ $num_a = "1" ];then
			 sed   -e   '/^#anon/s/^#//g'  -e '$i\anon_other_write_enable' -e '$i\allow_writeable_chroot=YES' -e  '$i\anon_world_readable_only=NO' /etc/vsftpd/vsftpd.conf
			 systemctl restart vsftpd
		else
			echo "好的我们不启动匿名服务权限"
			break
			
		fi
	chmod  777 /var/ftp/pub/	
        IP=$(ifconfig  ens33 |awk '/broadcast/{print $2}')
	ftp $IP

}

_Samba(){
samba=' samba  samba-client'
	rpm -q $samba && echo  "$samba 已经安装"  ||  yum install -y $samba
	systemctl status smb |grep  dead  &&   systemctl restart smb || echo "服务已经启动" 
	systemctl enable smb
	read	-p "输入你要共享的目录：" name_d
		[ -d $name_d ] && echo "此目录存在" ||  mkdir -p $name_d
	read	-p  "来取个你觉得很nice名字的共享的目录名字吧！小老弟：" name_a
 	read    -p  "你想要此目录任何人都可以看到吗？ 选择下吧：YES  or  NO"   name_b
	read	-p  "你是否允许任何人访问此目录？选择下吧 YES  or  NO : "  name_c		
		echo "默认具有写的权限，来吧展现你的文采"
		echo "[ $name_a ]
	comment =smb  smb  smb
     	path =$name_d
        browseable =$name_b
        public=$name_c
        writeable =YES" >> /etc/samba/smb.conf

        systemctl restart smb
	smbclient  -L localhost
	read -p "为用户设置smb密码：输入用户名:"  name_f
		id  $name_f   > /dev/null &&  echo  "用户存在"  || userad  $name_f  > /dev/null 
	pdbedit -L
	pdbedit  -a  dm
		
}

_httpd(){
httpd='httpd'
	rpm -q $httpd && echo "$httpd已经安装" || yum install -y $httpd
	systemctl status httpd  |grep  dead  &&   systemctl restart httpd  || echo "服务已经启动"
	systemctl  enable  httpd
	IP=$(ifconfig  ens33 |awk '/broadcast/{print $2}')
	echo '
	     ______________________________________
	    |					   |
	    |	           apache		   |
	    |					   |
	    |    1：      [ 添加用户认证 ]	   |
	    |					   |
	    |    2：      [ 虚拟主机     ]         |
	    |			 		   |
	    |    3：      [ 文件共享     ]	   |
	    |	 				   |
	    |    *:     [ 退出设置     ]	   |
	    |______________________________________|'
	while :
	do
		 read  -p  '请选择数字对应的项目:'  IP_a
case  $IP_a  in
1)           

#read -p   "请慎重考虑是否需要做用户认证: 撤回请按n退出:"  xuanze_a
#	if [ $xuanze_a="n" ];then
#		break
#	else
	    mv welcome.conf.bak  welcome.conf  
	    sed  -i '151s/AllowOverride None/AllowOverride  AuthConfig/' /etc/httpd/conf/httpd.conf   #将第151行None 替换为 AuthConfig！启用身份验证
	    cd    /var/www/html
	    [ -f .htaccess ]  &&  echo "文件存在"   ||  touch .htaccess 
	    echo "Authname web	       
AuthType Basic
Authuserfile /etc/httpd/conf/.htpass
require   valid-user" >.htaccess #&& echo  ”写入成功“    #将认证配置文件写入到/var/www/html目录下启用用户认证，httpd服务默认web访问/var/www/html目录
	   file_a=/etc/httpd/conf/.htpass
		   [ -e  $file_a ] && echo "文件存在"   ||  touch $file_a
	     [ -s  $file_a ]    
	    #num_f=`cat /etc/httpd/conf/.htpass |wc -l`
#	   echo $num_f  #输出.htpass里面存在的用户数量
	  # if [ $num_f!="0" ];then  #做判断当.htaccess文件没有用户存在
	   if [  $? -eq 0 ];then  #做判断当.htaccess文件没有用户存在
	  	 read -p "输入提供web服务的用户"  user_g
        	 id $user_g   &>2
	  	 if [ $? -eq 0 ];then
	   		htpasswd  -m /etc/httpd/conf/.htpass    $user_g
	  	 else
			echo "你输入的用户不存在"
	         fi
	   else
		read -p "输入提供web服务的用户"  user_g
                id $user_g  &>2
                if [ $? -eq 0 ];then
                        htpasswd  -cm /etc/httpd/conf/.htpass    $user_g
                else
                        echo "你输入的用户不存在"

		fi
	   fi	
#fi
;;
2)
	mv welcome.conf.bak  welcome.conf
	read	-p  "确定需要做web虚拟主机吗？y 或者 n  " xn_a
if [ $xn_a = "y" ];then
	url=/etc/httpd/conf.d/dm.conf
#		[ -f  dm.conf ] && "文件存在" || touch  /etc/httpd/conf.d/dm.conf
		sed  -n  '32,38p' /usr/share/doc/httpd-2.4.6/httpd-vhosts.conf > $url  #/etc/httpd/conf.d/dm.conf
		sed  -n  '124,128p'  /etc/httpd/conf/httpd.conf  >>  $url   #/etc/httpd/conf.d/dm.conf
		sed  -i '1c<VirtualHost *:80>'  $url  # /etc/httpd/conf.d/dm.conf
	#	read  -p "输入你的邮件地址"  xn_b
	read -p   "你要创建虚拟主机的主目录路径" xn_b
		[  -d  $xn_b  ]   &&   echo "目录存在"  ||  mkdir -p  $xn_b  
        	sed  -i "3cDocumentRoot "$xn_b""  $url
	read -p  "取一个域名吧" xn_c
		num_h=`echo $xn_c | awk '{print  length($0)}'` #获取输入域名的字符数
		#	echo $num_h   #获取取的域名字符个数
		if  [ $num!="0"  ];then
			sed -i  "4cServerName "$xn_c" "  $url 
		else
			echo "那就默认配置"
		fi
   			sed  -i  "5{s/dummy-host2.example/$xn_c/}"  $url
   			sed  -i  "6{s/dummy-host2.example/$xn_c/}"  $url
	read -p  "虚拟用户是否需要进行用户认证? y  或者 n " xn_d
	if [ $xn_d="y" ];then
		sed  -i   "9,11{s/ /#/}"   $url
	        sed   -e  '$i\Authname '  -e  '$i\AuthType Basic'   -e  '$i\Authuserfile /etc/httpd/conf/.vuerpass' -e  '$i\require   valid-user' $url 
		[ -f /etc/httpd/conf/.vuerpass ] && echo "文件存在" || touch /etc/httpd/conf/.vuerpass 
		num_g=`cat /etc/httpd/conf/.vuerpass |wc -l`
#          echo $num_g  #输出.htpass里面存在的用户数量
           	if [ $num_g!="0" ];then  #做判断当.vuerpass文件没有用户存在
		    read -p "输入提供web服务的用户"  user_f
                    id $user_f  &>2
                    if [ $? -eq 0 ];then
                 	   htpasswd  -m /etc/httpd/conf/.vuerpass    $user_f
                    else
                  	   echo "你输入的用户不存在"
                 fi
           	 else
                	read -p "输入提供web服务的用户"  user_f
                	id $user_f  &>2
                	if [ $? -eq 0 ];then
                        	htpasswd  -cm /etc/httpd/conf/.htpass    $user_f
               		 else
                        	echo "你输入的用户不存在"
         		 fi
          	 fi

	else	
		"好的，那就不做用户认证了"
 		break
	fi
		
else
	echo "好的，不做虚拟主机了"
	break
fi
;;
3)	
	lj_conf=/etc/httpd/conf.d
	pub=/var/www/html
	read -p  "输入你要共享的文件目录：" lj_k
	if [ -e  $lj_k ];then
        #找查/var/ww/html是否具有用户输入共享的目录
		[ -e  $pub/${lj_k} ] && echo  "已经共享${lj_K}" ||   ln -s   ${lj_k}   $pub
		ls  $pub 
	else
		read -p  "你共享的目录没有找到！你共享的目录还是文件 y:普通文件  n:文件目录" wj_a
			if [ $wj_a = y -o  $wj_a = Y ];then
				touch  $lj_k; ln -s   $lj_k  $pub
			elif [ $wj_a = N  -o  $wj_a = n ];then
                               mkdir -p $lj_k; ln -s   $lj_k   $pub
			else
				echo "输入上面正确选择"
				
			fi 
	fi
	#将/etc/httpd/conf.d所有.conf配置文件不加载
	conf=$(ls  -al /etc/httpd/conf.d/ |grep -Ev  "autoindex.conf|userdir.conf"|grep -E  \*.conf$|awk '{print $NF}' )
	for  i in ${conf[@]} 
	do
		mv  ${lj_conf}/$i  ${lj_conf}/$i\.bak
	done
	#判断web目录是否有index.html文件，有的话web服务先加载.html配置文件无法进行文件共享服务
	[ -e ${pub}/index.html ] && rm -rf ${pub}/index.html
#	systemctl reload  httpd
	
	
;;
*)
	#echo  "我的IP是$IP" > /var//www/html/index.html
        echo "去浏览访问吧$IP"
	break
;;
esac
	done
}
_DHCP(){
DHCP='dhcp'
	rpm -q $DHCP && echo "$DHCP已经安装" || yum install -y $DHCP
	systemctl status  named  |grep  dead  &&   systemctl restart named || echo "服务已经启动"
	sed -n '47,55p' /usr/share/doc/dhcp-4.2.5/dhcpd.conf.example  >/etc/dhcp/dhcpd.conf
	sed  -i  -e  's/10.5.5.1/10.5.5.1.2/'  -e  's/255.255.255.224/255.255.255.0/'   -e  's/10.5.5.1.31/192.168.11.254/' /etc/dhcp/dhcpd.conf
        systemctl restart named
}

_PXE(){
PXE='tftp-server syslinux mlocate vsftpd'
servers='tftp vsftpd '
IP=$(ifconfig  ens33 |awk '/broadcast/{print $2}')
repo_a=`df |grep /dev/sr0  |awk   '{print $6}'`
files=/var/lib/tftpboot

	#调用DHCP脚本
	_Yum    > /dev/null
	_DHCP   
	sed -i -e '$i\  next-server  192.168.11.11 ;' -e '$i\  filename  "pxelinux.0" ;'  /etc/dhcp/dhcpd.conf
	rpm -q $PXE && echo "$PXE已经安装" || yum install -y $PXE
	systemctl status  $servers  |grep  dead  &&   systemctl restart  $servers || echo "服务已经启动"
        systemctl  enable $servers
	updatedb
	locate  pxelinux.0 
	cp /etc/xinetd.d/tftp{,.bak}
	[ -f /usr/share/syslinux/pxelinux.0 ]  && cp /usr/share/syslinux/pxelinux.0  /var/lib/tftpboot ||  break
	sed -i  '/disable/s/yes/no/g'   /etc/xinetd.d/tftp
	cp  $repo_a/isolinux/*    $files
	cd  $files
	[ -d   pxelinux.cfg ] || mkdir pxelinux.cfg;cp isolinux.cfg  pxelinux.cfg/default
 	mount /dev/sr0   /var/ftp/pub/
	sed -i '64c\append initrd=initrd.img/method=ftp://192.168.11.11/pub/g'  $files/pxelinux.cfg/default
	 systemctl restart  $servers 
	 systemctl restart  vsftpd	
	

}
_DNS(){
DNS='bind bind-utils'
	rpm -q $DNS && echo "$DNS已经安装" || yum install -y $DNS
	systemctl status  named  |grep  dead  &&   systemctl restart namd || echo "服务已经启动"
        systemctl  enable  named

}

_Selinux(){
		systemctl status  firewalld  |grep dead  &&   echo "服务已经关闭" ||  systemctl stop firewalld
		systemctl disable  firewalld
		selinux=$(getenforce )
		if [  "$selinux" = "Permissive" ];then
			echo "宽限模式，已经临时关闭selinux"	
		elif [ "$selinux" = "Enforcing" ];then
			echo "开启模式"
			read -p "是否关闭selinux YES  or  NO:\t" xuan_a
			 if  [ $xuan_a = YES -o   $xuan_a = yes -o  $xuan_a = y  ];then
			       setenforce 0
			       echo "已经临时关闭selinux"
			else
				echo "那就不关闭selinux"
			
			fi
		else 
			echo "已经关闭"
		fi
		
		
}

_Yum(){
repo_a=`df |grep /dev/sr0  |awk   '{print $6}'`
umount $repo_a
[ -d  /iso ]  &&  echo '/iso目录存在'  || mkdir -vp  /iso
sleep 2s
(df | grep "/dev/iso")  &&  echo '/iso已经挂载'  || mount /dev/cdrom /iso
sleep 2s
[ -d /etc/yum.repos.d/bak ]  &&  echo '/etc/yum.repos.d/bak目录存在' ||  mkdir  -pv /etc/yum.repos.d/bak
sleep 2s
[ -f /etc/yum.repos.d/*.repo ]  &&  mv -vf /etc/yum.repos.d/*.repo  /etc/yum.repos.d/bak || echo '没有发现后缀为.repo的普通文件'
echo '
[cnetos7.2]
name=centos7.2
baseurl=file:///iso
enabled=1
gpgcheck=0
'> /etc/yum.repos.d/iso.repo
yum clean all; yum  repolist; yum makecache
[ -f /etc/yum.repos.d/bak/iso.repo ]  &&  rm -rf  /etc/yum.repos.d/bak/iso.repo  || echo '没有发现iso.repo普通文件'
df
}


_Adduser(){
read -p "你要删除用户还是创建用户呢？1:创建 2:删除" user_a
if [ "$user_a" = "1" ];then
	read -p "你可以创建多个或者单个用户:"  -a  users
	for i in  ${users[@]} #循环数组提取用户
	do	
        	id $i  &>2     #将错误的输出不显示
        	if [ $? -eq 1 ];then    #当上面返回的状态码为1时，执行以下的步骤
			echo   "你创建用户个数为 ${#users[@]}个:  ${users[@]}"  # ${users[@]}——>数组，  指的是输入创建的用户。
                	useradd  $i   #创建用户
               		read -p "用户${i}请你设置密码" -s  mima   #-s 是用户输入密码时隐藏密码
                		echo  $mima | passwd  --stdin   ${i}     
                		echo  "${i}用户创建成功并且密码设置成功"
        	else
                	echo "${i}用户存在"     #当id $i 返回状态码为0的时候执行此命令（shell脚本 0为正确 1为错误）
       		 fi

	done

elif  [ "$user_a" = "2" ];then
	read -p  "你可以单个或者多个删除的用户:"  -a  user_b
		id $user_b   &>2
		if [ $? -eq 0 ];then
		   	echo "你删除的用户数量为${#user_b[@]}个: ${user_b[@]}"
			        for  z  in  ${user_b[@]}
			 		do
		    				 userdel  -r $z
		     	 			 echo "${z}用户删除成功"
			 	 	done
		else
			echo "不好意思你输入的${user_b}不存在"		       
		fi
	
else
	 continue
	

fi
}
_exit(){
	echo "退出成功"
	exit
}

clear
while  :
do
_MENU
	read  -p  'input  choice:'  i
case  $i  in
1)
    _NFS
;;
2)
    _Vsftpd
;;
3)
    _Samba
;;
4)
    _httpd
;;
5)
    _DHCP
;;
6)
    _PXE
;;
7)
    _DNS
;;
8)
    _Selinux
;;
9)
    _Yum
;;
10)
   _Adduser
;;
11)
   _exit
;;
*)
    echo  'input  error,shell  exit.Next  running  input  true  option  number.'
;;
esac
done
