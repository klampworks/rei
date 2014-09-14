#!/bin/sh

#TODO Not Google...
nameserver=8.8.8.8

echo "nameserver $nameserver" > /etc/resolv.conf.head
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT -o $interface  -d $nameserver \
	 -m owner --uid-owner rei
