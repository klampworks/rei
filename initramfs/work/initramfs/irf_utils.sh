#!/bin/busybox sh

# Prints an error for the user if a given argument does not appear in the 
# `mount` output.
check_mounted() 
{
	if ! mount | grep $1 > /dev/null; then
		echo "WARNING: $1 does not appear to be mounted."
	fi
}

# Keymaps are important for passwords since no two countries can agree where 
# the fucking symbols on a keyboard should go.
load_keymap()
{
	if [[ ! -d /dev/vc ]]; then
		mkdir /dev/vc
	fi
	  
	if [[ ! -f /dev/vc/0 ]]; then
		ln -s /dev/console /dev/vc/0
	fi

	if [[ ! -f /etc/keymap ]]; then
		echo "Place keymap in /etc/keymap and rebuild."
	fi

	loadkmap < /etc/keymap
}

# Given a disk UUID, return the dev name i.e.
# f81d4fae-7dec-11d0-a765-00a0c91e6bf6 --> /dev/sdb3
find_mnt()
{
	blkid | sed -n "/$1/s/\([^:]\+\).*/\1/p"
}

# Mount $1 at mount point $2 with options $3.
mount_this()
{
	mkdir -p $2
	mount $3 $1 $2 &> /dev/null
	sleep 1
}

prepare_sqfs()
{
	#$1 UUID
	#$2 squashfs filename
	#
	#sqfs file will be copied into ram at /$1
	#

	root=$(find_mnt $1)
	mount_this $root $1
	echo "Copying $2..."
	cp "$1/$2" $2
	echo "Done!"
	umount $1
	mount_this $2 $1
}

prepare_tmpfs()
{
	#$1 mount point.
	mount_this "none" $1 "-t tmpfs"
}

union_mount()
{
	#$1 UUID of media containing sqfs file.
	#$2 filepath of sqfs file relative to mount point.
	#$3 tmpfs name
	#$4 mount point

	prepare_sqfs $1 $2
	prepare_tmpfs $3
	/bin/unionfs -o dirs=$3=rw:$1=ro $4
}

union_mount_vm()
{
	#$1 Mounted sqfs path.
	#$2 tmpfs name
	#$3 mount point

	prepare_tmpfs $2
	/bin/unionfs -o dirs=$2=rw:$1=ro $3
}

basic_setup()
{
	#Disable kernel messages from popping onto the screen
	echo 0 > /proc/sys/kernel/printk

	#Wait for kernel messages to subside.
	sleep 2
	clear


	/bin/busybox --install -s
	mount -t proc none /proc
	mount -t sysfs none /sys

	check_mounted /proc
	check_mounted /sys

	#Create device nodes
	mknod /dev/tty c 5 0
	mdev -s

	load_keymap
}
