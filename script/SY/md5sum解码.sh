#!/bin/bash
for i in `seq 0  99999`
do
	#将数字转换为md5的编码格式字符
	nums=`echo $i | md5sum | cut -c 1-8` 
	for  j  in `cat /root/sh/SY/a.txt`
	do
		if [ $nums = $j ];then
			echo "$nums解析出来的数字为：$i"
		fi
	done
	
done
