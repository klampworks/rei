#!/bin/sh

#TODO Might want multiple shares with different names at some point.
#i.e. one for logs...
mount -t 9p -o trans=virtio,noexec share /share
