#!/bin/sh --> Creator : Linux_x189 v0.0.6 Share under  GPL v2 Licence
PATH=/:/bin
mount -t proc proc /proc
mount -t rootfs -o remount,rw rootfs /
mount -t devtmpfs dev /dev
insmod /lib/modules/aufs.ko 1>/dev/null 2>&1 || echo ERROR 
module_version="3.7.2-gentoo"
#########Storage scan###################
timer=2
while [[ $timer != 0 ]];do
  sto_num_pre=`blkid 2>/dev/null |wc -l`
	sleep ${timer}
	sto_num_after=`blkid 2>/dev/null |wc -l`
	if [[ ${sto_num_pre} == ${sto_num_after} ]]; then
		timer=`expr ${timer} - 1`
	fi
done
########LVM init#######################
Green_msg(){
	echo -ne "[0;32m$1\n[0;39m"
}
Red_msg(){
	echo -ne "[0;31m$1\n[0;39m"
}
#########Default option###################
real_root="/.live/root"

for dir in ro rw root device ; do
	mkdir -p /.live/${dir}
done
Mount(){
if blkid |grep -i "${1}" |grep -iq "ntfs" ; then
	ntfs-3g $1 $2 1>/dev/null 2>&1
else
	mount   $1 $2 1>/dev/null 2>&1
fi
}
for cmd in `cat /proc/cmdline`; do
	case $cmd in
		img=*)
			img=${cmd#*=}
			;;
		fresh)
			fresh=1
			;;
		UUID=*|uuid=*)
			UUID=${cmd#*=}
			;;
		user=*)
			user=${cmd#*=}
			;;
		dolvm)
			dolvm=1
			lvm vgchange -ay --sysinit && \
			lv_part=`lvm lvdisplay|grep "LV Path" |cut -dh -f2`
			;;
		save=*)
			save_file=${cmd#*=}
			;;
		root=*)
			root=${cmd#*=}
			;;
	esac
done

hd_part=`blkid |grep -iEv "lvm|mdadm" | grep -iE "${UUID}" |cut -d: -f 1 |tac`
if [[ "${dolvm:-0}" == 1 ]]; then device_list="${hd_part} ${lv_part}";fi

Img_search(){ 		#Search for which partition holding the root image
for device in  ${device_list:-${hd_part}}; do
			Mount "$device" "/.live/device"   
	while true;do
		if cat /proc/mounts |grep -q "/.live/device" ; then
			break
		else
			Mount "$device" "/.live/device"  
		fi
	done
	if ls /.live/device |grep -q ${1}; then
		break

	else
		umount $device
	fi
done	
[[ ! -f "/.live/device/${1}" ]] && Red_msg "Cannot Find ${1} \
image . Exit... Ctrl+Alt+Del to reboot" && sleep 9999     || \
	Green_msg "Found!" && sleep 2
}

Savfile_check(){	#Check if the Savefile works
[[ -e /.live/device/${1} ]] && \
      echo "Savefile Exist" && \
if mount -o loop,rw /.live/device/${1} /.live/rw 1>/dev/null 2>&1 ; then
	Green_msg "Savefile:${1} works"
	umount /.live/rw
	return 0
else	
	Red_msg "But it does not work"
	return 1
fi
}

Aufs_img_mount() {
if Savfile_check ${1} && [[ ${fresh:-0} == 0 ]]; then  
	mount  -n -t auto   -o loop,rw        /.live/device/${1} /.live/rw
	while true;do
		if cat /proc/mounts |grep -q "/.live/rw" ; then
			break
		else
		mount  -n -t auto   -o loop,rw        /.live/device/${1} /.live/rw
		fi
	done
    else
	mount  -n -t tmpfs  -o mode=0777      tmpfs /.live/rw && Green_msg "Start a new system"
fi
	mount  -n -t squashfs -o loop,ro /.live/device/${2} /.live/ro
	mount  -n -t aufs     -o br:/.live/rw=rw:/.live/ro=ro aufs /.live/root
}
Aufs_disk_mount(){
	mount  -n -t tmpfs tmpfs -o mode=0777		       /.live/rw  
	mount  -n -t auto  ${1}  -o ro			       /.live/ro
	mount  -n -t aufs  aufs  -o br:/.live/rw=rw:/.live/ro=ro  /.live/root
}
User_add(){
if [[ -n "${1}" ]]; then
	Green_msg "Your login USER account is ${1}" 
	sed -i -e '/^root/s/x//' ${real_root}/etc/passwd
	cat ${real_root}/etc/passwd |grep -iq "${1}" || \
	cat >> ${real_root}/etc/passwd << EOF
${1}::1500:1500::/home/${1}:/bin/bash
EOF
	cat ${real_root}/etc/group |grep -iq "${1}" || \
		{
			local group
			cat >> ${real_root}/etc/group << EOF
${1}:x:1500:
EOF
			for group in disk wheel audio cdrom video users;do
				if cat ${real_root}/etc/group |grep "${group}" |grep -iq ":$";then
					sed -i -e "/^${group}/s/.*/&${1}/" ${real_root}/etc/group
				else
					sed -i -e "/^${group}/s/.*/&,${1}/" ${real_root}/etc/group 
				fi

			done
			mkdir -p ${real_root}/home/${1}
			chown -R 1500:1500 ${real_root}/home/${1}
			[[ -e "${real_root}/etc/sudoers" ]] && \
				echo "${1} ALL=(ALL) NOPASSWD: ALL" >> ${real_root}/etc/sudoers
		}
fi
}


if [[ -z "${root}" ]];then
	Green_msg "Search for ${img}"
	Img_search ${img:-"gentoo.squ"} && \
	Aufs_img_mount ${save_file:-"disk.img"} ${img} || sleep 9999

	[[ -n "${user}" ]] && User_add ${user}
else
	Green_msg "Start from your linux on DISK" 
	Aufs_disk_mount ${root}
fi
[[ -e ${real_root}/lib/modules/${module_version} ]] || mkdir -p ${real_root}/lib/modules && \
	cp -r /lib/${module_version} ${real_root}/lib/modules 2>/dev/null

for dir in `ls -1 /.live/`; do
	if [ "$dir" != "root" ]; then
		mkdir -p $real_root/.live/$dir
		mount --move /.live/$dir $real_root/.live/$dir
	fi
done
mount -t devtmpfs dev ${real_root}/dev
umount  /proc
exec switch_root /.live/root /sbin/init 1>/dev/null 2>&1 
