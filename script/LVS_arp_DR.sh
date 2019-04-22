#!/bin/bash
echo 1 > /proc/sys/net/ipv4/conf/ens33/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/ens33/arp_announce
echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl  -p
