#!/bin/sh

tor_port="9050"
tor_user="tor"
interface="enp0s3"

iptables -I INPUT -j ACCEPT -i lo -p tcp --dport $tor_port --sport 1:65000
iptables -A OUTPUT -j ACCEPT -o lo -p tcp --dport 1:65000 --sport $tor_port

iptables -A OUTPUT -p tcp -j ACCEPT -m owner --uid-owner $tor_user -o lo

iptables -A OUTPUT -p tcp -j ACCEPT -o $interface -m owner --uid-owner $tor_user
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
