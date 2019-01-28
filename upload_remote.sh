#!/bin/bash

#set -x

if [ $1 ]
then
    scp $1 root@192.168.1.21:../boot/grub2/
else
    scp kernel.elf root@192.168.1.21:../boot/grub
fi
