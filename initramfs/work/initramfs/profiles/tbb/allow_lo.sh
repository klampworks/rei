#!/bin/sh

iptables -A INPUT -p tcp -j ACCEPT -i lo
iptables -A OUTPUT -p tcp -j ACCEPT -o lo

# TODO I can't get fucking xpra to work without allowing all traffic on lo...
#iptables -A OUTPUT -p tcp -j ACCEPT -m owner --uid-owner $user_user -o lo

