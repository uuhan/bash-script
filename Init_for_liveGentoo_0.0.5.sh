#!/bin/sh --> Creator : Linux_x189 v0.0.5 Share under  GPL v2 Licence
PATH=/:/bin
mount -t proc proc /proc
mount -t rootfs -o remount,rw rootfs /
mount -t devtmpfs dev /dev
insmod /lib/modules/aufs.ko
#~~~~~~~~Storage scan~~~~~~~~~~~~~~~~~~~
timer=3
while [[ $timer != 0 ]];do
  sto_num_pre=`blkid 2>/dev/null |wc -l`
	sleep ${timer}
	sto_num_after=`blkid 2>/dev/null |wc -l`
	if [[ ${sto_num_pre} == ${sto_num_after} ]]; then
		timer=`expr ${timer} - 1`
	fi
done
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
UUID=''
user=''

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
		UUID=*|uuid=*)
			UUID=${cmd#*=}
			;;
		user=*)
			user=${cmd#*=}
			;;
	esac
done
Green_msg "Search for ${Sys}"
for device in `blkid |grep -iEv "lvm|ntfs" | grep -iE "${UUID}" |cut -d: -f 1 |tac` ; do
	mount $device /.live/device 
	while true;do
		if cat /proc/mounts |grep -q "/.live/device" ; then
			break
		else
			mount $device /.live/device  1>/dev/null 2>&1 
		fi
	done
	if ls /.live/device |grep -q ${Sys}; then
		Green_msg "Found!" && sleep 1
		[[ -e /.live/device/${Save_file} ]] && \
		fresh_A=1
		break
	else
		umount $device
	fi
done	
[[ ! -f "/.live/device/${Sys}" ]] && Red_msg "Cannot Find ${Sys} \
image . Exit... Ctrl+Alt+Del to reboot" && sleep 9999
[[ -e /.live/device/${Save_file} ]] && \
	echo "Savefile Exist" && \
if mount -o loop /.live/device/${Save_file} /.live/rw 1>/dev/null 2>&1; then
	fresh_B=1
	Green_msg "Savefile works"
	umount /.live/rw
else	
	Red_msg "But it does not work"
fi

real_root="/.live/union"
if [[ ${fresh_A} = 1 && ${fresh_B} = 1 && ${fresh_C} = 1 ]]; then  
	mount  -n -t ext2 -o loop,rw /.live/device/disk.img /.live/rw
    else
	mount  -n -t tmpfs tmpfs /.live/rw && Green_msg "Start a new system"
fi

mount  -n -t squashfs -o loop,ro /.live/device/${Sys} /.live/ro
mount  -n -t aufs -o br:/.live/rw:/.live/ro=ro aufs /.live/union
if [[ -n "${user}" ]]; then
	Green_msg "Your login USER account is ${user}" 
	sed -i -e '/^root/s/x//' ${real_root}/etc/passwd
	cat ${real_root}/etc/passwd |grep -iq "${user}" || \
	cat >> ${real_root}/etc/passwd << EOF
${user}::1500:1500::/home/${user}:/bin/bash
EOF
	cat ${real_root}/etc/group |grep -iq "${user}" || \
		{
			local group
			cat >> ${real_root}/etc/group << EOF
${user}:x:1500:
EOF
			for group in disk wheel audio cdrom video users;do
				if cat ${real_root}/etc/group |grep "${group}" |grep -iq ":$";then
					sed -i -e "/^${group}/s/.*/&${user}/" ${real_root}/etc/group
				else
					sed -i -e "/^${group}/s/.*/&,${user}/" ${real_root}/etc/group 
				fi

			done
			mkdir -p ${real_root}/home/${user}
			chown -R 1500:1500 ${real_root}/home/${user}
			[[ -e "${real_root}/etc/sudoers" ]] && \
				echo "${user} ALL=(ALL) NOPASSWD: ALL" >> ${real_root}/etc/sudoers
		}
fi
for dir in `ls -1 /.live/`; do
	if [ "$dir" != "union" ]; then
		mkdir -p $real_root/.live/$dir
		mount --move /.live/$dir $real_root/.live/$dir
	fi
done
umount  /proc
exec switch_root /.live/union /sbin/init 1>/dev/null 2>&1 || \
	exec /bin/sh > /dev/console 2>/dev/null 
