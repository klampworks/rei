#!/bin/sh

if [ -z $1 ] && [ -z $2 ]
then
	src=share
	dst=/share
else
	src=$1
	dst=$2
fi
	
#TODO Might want multiple shares with different names at some point.
#i.e. one for logs...
mount -t 9p -o trans=virtio,noexec "$src" "$dst"
