#!/bin/sh --> Creator : Linux_x189 v0.3  Share under  GPL v2 Licence
PATH=/:/usr:/usr/bin:/usr/sbin:/bin:/sbin
mount -t proc proc /proc
mount -t rootfs -o remount,rw rootfs /
mount -t devtmpfs dev /dev
modprobe aufs || insmod /lib/modules/aufs.ko
Green_msg(){
  echo -ne "[0;32m$1\n[0;39m"
}
Red_msg(){
	echo -ne "[0;31m$1\n[0;39m"
}
#~~~~~~~~Default option~~~~~~~~~~~~~~~~~~~
Sys=gentoo.squ   #LiveImg by default
Save_file=disk.img
fresh_A=0; fresh_B=0; fresh_C=1 #Test condition whether the Imgfile is usable

for dir in ro rw union device ; do
	mkdir -p /.live/${dir}
done
for cmd in `cat /proc/cmdline`; do
	case $cmd in
		img=*)
			Sys=${cmd#*=}
			;;
		fresh)
			fresh_C=0
			;;
	esac
done
Green_msg "Search for ${Sys}"
for device in `blkid | cut -d: -f 1` ; do
	mount $device /.live/device 2>/dev/null
	if ls /.live/device |grep -n ${Sys}; then
		Green_msg "Found!" && sleep 1
		[[ -e /.live/device/${Save_file} ]] && \
		fresh_A=1
		break
	else
		umount $device
	fi
done	
[[ -f "/.live/device/${Sys}" ]] || Red_msg "Cannot Find Sys \
image . Exit..." 
if mount -o loop /.live/device/${Save_file} /.live/rw 1>/dev/null 2>&1; then
	fresh_B=1
	umount /.live/rw
fi
real_root="/.live/union"
if [[ ${fresh_A} = 1 && ${fresh_B} = 1 && ${fresh_C} = 1 ]]; then  
	mount  -n -t ext2 -o loop,rw /.live/device/disk.img /.live/rw
    else
	mount  -n -t tmpfs tmpfs /.live/rw && Green_msg "Start a new system"
fi

mount  -n -t squashfs -o loop,ro /.live/device/${Sys} /.live/ro
mount  -n -t aufs -o br:/.live/rw:/.live/ro=ro aufs /.live/union
[[ -e /.live/device/${Save_file} ]] && \
echo "Exist"
for dir in `ls -1 /.live/`; do
	if [ "$dir" != "union" ]; then
		mkdir -p $real_root/.live/$dir
		mount --move /.live/$dir $real_root/.live/$dir
	fi
done
umount  /proc
exec switch_root /.live/union /sbin/init
