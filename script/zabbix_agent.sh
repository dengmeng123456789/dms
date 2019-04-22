Zabbix_Agent=' /etc/zabbix/zabbix_agentd.conf'
Host_name=`cat /etc/hostname`
IP=$(ifconfig  ens33 |awk '/broadcast/{print $2}')
sed  -i  "97s/Server=127.0.0.1/Server=$IP/g"   $Zabbix_Agent
sed  -i  "138s/ServerActive=127.0.0.1/ServerActive=$IP/g"  $Zabbix_Agent
sed  -i  "149s/Hostname=Zabbix server/$Host_name/g"  $Zabbix_Agent
sed  -i -e  "105s/#//g"  -i -e  "113s/#//g  $Zabbix_Agent"
##允许接收远程命令，把接收的远程命令记入日志
sed -i -e "73i\EnableRemoteCommands=1" -i  -e  "82i\LogRemoteCommands=1" $Zabbix_Agent
#zabbix用户进行免密登入
sed  -i   "92i\zabbix  ALL=(ALL) NOPASSWD: ALL"   /etc/sudoers

