#!/bin/bash
rm $2
mksquashfs $1 $2 -comp xz -ef exclude
