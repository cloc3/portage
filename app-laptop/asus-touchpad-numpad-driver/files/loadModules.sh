#!/bin/bash - 
for module in i2c_dev uinput ; do {
	lsmod|grep ${module} -s -q || modprobe ${module}
	[ $? == 0 ] || exit 1
}; done
