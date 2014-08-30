#!/bin/bash

if [ -z $1 ]
then
	echo "Usage $0 </path/to/disk> <uuid>"
	exit 1
fi

default="1aa7420e-2897-4cc5-b43a-15ec79976b7c"
if [ -z $2 ]
then
	echo "No uuid, using default $default"
	uuid=$default
else
	uuid=$2
fi

cryptsetup luksFormat $1 --use-urandom --batch-mode -d $0 \
	--uuid $default
