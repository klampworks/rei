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
	#TODO, embed a Perl interpreter and fuck this sed bullshit
	res=$(echo $1 | sed -n '{s/\([0-9a-f]\{8\}-[0-9a-f]\{4\}\-[0-9a-f]\{4\}\-[0-9a-f]\{4\}-[0-9a-f]\{12\}\)/\1/p}')

	if [ -z "$res" ]
	then
		return
	fi

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

#$1 rw branch
#$2 ro branch
#$3 mount point
union()
{
	#Copy on write is mandatory when there is a read only branch.
	#Allow other is needed for non-root file access.
	#rw branch must be "on top", otherwise changes do not propagate.
	/bin/unionfs -o cow,allow_other,dirs=/tmpfs=rw:/sqfs=ro /mnt
}

#$1 mount point
#$2 init (optional).
switch()
{
	if [ -z "$2" ]
	then
		init=/sbin/init
	else
		init=$2
	fi

	echo "Switching root..."

	#System will be inoperable without these directories, best make sure.
	mkdir -p /mnt/run/ /mnt/dev/ /mnt/sys /mnt/proc /mnt/var/log/
	mount -t devtmpfs none /mnt/dev

	umount /sys /proc

	#Switch to the new root and execute init
	if [[ -x "${1}/${init}" ]] ; then
		exec switch_root "${1}" "${init}"
	fi

	basic_setup
	#This will only be run if the above line failed
	echo "Failed to switch_root, dropping to a shell"
	exec sh
}

#$1 uuid of disk
one_time_swap()
{
	disk=$(find_mnt $1)

	if [ -z "$disk" ]
	then
		echo "Could not find disk $1, no swap created."
		return
	fi

	dd if=/dev/urandom of=/key bs=1 count=32
	cryptsetup luksFormat $disk --use-urandom --batch-mode -d \
		/key --uuid $1

	cryptsetup luksOpen $disk swap -d /key

	dd if=/dev/urandom of=/key bs=1 count=32

	mkswap /dev/mapper/swap
	swapon /dev/mapper/swap
}

get_opt() 
{
	echo "$@" | cut -d "=" -f 2
}

parse_argv()
{
	for i in $(cat /proc/cmdline); do
		case $i in
			profile\=*)
				profile=$(get_opt $i)
				;;
			swap\=*)
				swap=$(get_opt $i)
				;;
		esac
	done
}

cp_mod()
{
	dest="/mnt/etc/local.d"

	for ARG in "$@"
	do
		cp "/profiles/common/$ARG" "$dest"
	done
}

prof_skype()
{
	rm -rf /mnt/etc/local.d/*
	cp /profiles/skype/* /mnt/etc/local.d/
	cp_mod 	mount_9p.sh \
		allow_dns.sh

	chmod +x /mnt/etc/local.d/*
}

load_profile()
{
		case $profile in
			tbb)
				rm -rf /mnt/etc/local.d/*
				cp /profiles/tbb/* /mnt/etc/local.d/
				cp_mod 	mount_9p.sh \
					deny_all.sh \
					allow_lo.sh \
					allow_tor.sh \
					allow_ssh.sh

				chmod +x /mnt/etc/local.d/*
				;;
			irc-freenode)
				rm -rf /mnt/etc/local.d/*
				cp /profiles/irc/* /mnt/etc/local.d/
				cp_mod 	mount_9p.sh \
					deny_all.sh \
					allow_lo.sh \
					allow_dns.sh \
					allow_ssh.sh

				chmod +x /mnt/etc/local.d/*
				;;
			skype)
				prof_skype
			;;
			*)
				echo "Unknown profile <$profile>."
				exec sh	
				;;
		esac
}
