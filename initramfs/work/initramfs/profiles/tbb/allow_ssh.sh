#!/bin/sh
iptables -I INPUT -p tcp --dport 22 -s 192.168.100.1 -j ACCEPT
iptables -I OUTPUT -p tcp --sport 22 -d 192.168.100.1 -j ACCEPT
