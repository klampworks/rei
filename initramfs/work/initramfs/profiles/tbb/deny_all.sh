#!/bin/sh

iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

iptables -P INPUT DROP
iptables -P OUTPUT DROP
