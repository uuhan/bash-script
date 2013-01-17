#!/bin/sh --> Creator : Linux_x189 v0.2  Share under  GPL v2 Licence
PATH=/:/usr:/usr/bin:/usr/sbin:/bin:/sbin
mount -t proc proc /proc
mount -t rootfs -o remount,rw rootfs /
mount -t devtmpfs dev /dev
modprobe aufs || insmod /lib/modules/aufs.ko
for dir in ro rw union device ; do
  mkdir -p /.live/${dir}
done
for cmd in `cat /proc/cmdline`; do
	case $cmd in
		img=*)
			image=${cmd#*=}
			break
			;;
		*)
			;;
	esac
done
echo "Search for ${image}"
for device in `blkid | cut -d: -f 1` ; do
	mount $device /.live/device 2>/dev/null
	if ls /.live/device |grep -n ${image}; then
		echo "Found!" && sleep 1
		break
	else
		umount $device
	fi
done	
[[ -z "${image}" ]] && echo "Cannot found image file" && exit 1
real_root="/.live/union"
#mount  -n -t tmpfs tmpfs /.live/rw
mount  -n -t ext2 -o loop,rw /.live/device/disk.img /.live/rw
mount  -n -t squashfs -o loop,ro /.live/device/${image} /.live/ro
mount  -n -t aufs -o br:/.live/rw:/.live/ro=ro aufs /.live/union
[[ -e /.live/device/disk.img ]] && \
echo "Exist"
for dir in `ls -1 /.live/`; do
	if [ "$dir" != "union" ]; then
		mkdir -p $real_root/.live/$dir
		mount --move /.live/$dir $real_root/.live/$dir
	fi
done
umount  /proc
exec switch_root /.live/union /sbin/init
