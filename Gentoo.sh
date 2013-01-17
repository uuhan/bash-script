#!/bin/bash
#
# Gentoo.sh --help for somehelp
#  Author: Linux_x189
#	Version: 0.0.2
#	This is a free software .You can redistribute it under LGPL liscense
#
Portage="portage-2.1.11.31.tar.bz2"
MD5_portage="5419f25d248c50fb8cef5d44f44a4922"
Green_msg(){
	echo -ne "[0;32m""$1\n""[0;39m"
}
Red_msg(){
	echo -ne "[0;31m""$1\n""[0;39m"
}
Help_msg(){
	echo "Usage: A script aim to Simplify Installation of distro of Gentoo"
	echo "For more info use ${0#*/} --help"
	Green_msg "AUTHOR: Linux_x189" 
}
Root_warn(){
	if [[ ! "0$UID" -eq 0 ]]; then
		Red_msg "You should be the root user for the following installation"
		Help_msg
		exit 1
	fi
}
 [[ -z "$1" ]] && \
	Help_msg && \
	exit 0
#Essential Check
if [[ ! -x `which wget` ]]; then
	Red_msg "You Need Wget being Installed"
	Help_msg
	exit 1
fi

case "$1" in
	--help|-h) 
           Green_msg "This script ${0#*/} is used for installing portage in \
non-Gentoo linux disto or installing a new Gentoo distro for you"
		echo "	USAGE:"
		echo "		${0#*/} [OBJECT] [ACTION] [PATH]"
		echo "		Valid OBJECT:"
             Red_msg "			Portage Gentoo LFS"
		echo "		Valid ACTION:"
             Red_msg "			Install Uninstall"
		Green_msg "AUTHOR: Linux_x189" 
		exit 0 ;;
	--version|-v) 
		Green_msg "AUTHOR: Linux_x189" 
		Green_msg "Version: 0.0.1"
		;;
	esac
Portage_Install(){
	Root_warn
	ROOT=$1
	#必须的目录
	if [[ -n "$1" ]]; then
		for Dir in /tmp /usr/lib/portage /var/tmp/portage /usr/portage /etc/portage /usr/share/portage/config; do
			[[ -d ${ROOT}$Dir ]] || mkdir -pv ${ROOT}$Dir
			[[ -d $Dir ]] || mkdir -pv $Dir
			mount --rbind ${ROOT}${Dir} ${Dir}
		done
	fi
	[[ -d ${ROOT}/usr/bin ]] || mkdir -pv ${ROOT}/usr/bin
	#Protage 
	[[ -e ${ROOT}/tmp/${Portage} ]] && \
		[[ `md5sum ${ROOT}/tmp/${Portage} |cut -d' ' -f1` == ${MD5_portage} ]] || \
	wget -cP ${ROOT}/tmp http://distfiles.gentoo.org/distfiles/${Portage} 2>&1
	cd ${ROOT}/tmp && tar xvf ${Portage}

	wget -cP ${ROOT}/tmp http://distfiles.gentoo.org/releases/snapshots/current/portage-latest.tar.xz
	tar xf ${ROOT}/tmp/portage-latest.tar.xz -C ${ROOT}/usr/
	cp -r ${ROOT}/tmp/${Portage%.tar.bz2}/{pym,bin} ${ROOT}/usr/lib/portage/
	cp -r ${ROOT}/tmp/${Portage%.tar.bz2}/cnf/make.globals ${ROOT}/usr/share/portage/config
	ln -svf ${ROOT}/usr/lib/portage/bin/emerge ${ROOT}/usr/bin/emerge
	export PATH=$PATH:${ROOT}/usr/lib/portage/bin:${ROOT}/usr/bin
	export ROOT=${ROOT}
	#用户和组的添加
	grep -q portage /etc/group || \
		cat >> /etc/group << EOF
portage::250:portage
EOF
	groupadd portage -g 250
	grep -q portage /etc/passwd || \
		cat >> /etc/passwd << EOF
portage:x:250:250:portage:/var/tmp/portage:/bin/fales
EOF
	ln -svf /usr/portage/profiles/default/linux/x86/10.0/ /etc/portage/make.profile
	emerge --sync
	emerge --metadata
}
Portage_Uninstall(){
	echo "Do you really want to Uninstall portage from you system? (Y/N)"	 
	local choice dir ROOT
	ROOT=$1
	read choice
	case $choice in
		Y|y) ;;
		*) exit ;;
	esac
	Root_warn 
	sed -i -e '/^portage/d' ${ROOT}/etc/group
	sed -i -e '/^portage/d' ${ROOT}/etc/group
	for dir in "/usr/share/portage" "/usr/portage" "/etc/portage" "/var/tmp/portage" "/usr/lib/portage"; do
		rm -rf $ROOT$dir
		done
}
case "$1" in
	Portage) 
		case "$2" in
			Install)
				if [[ -d "$3" ]]; then
					Portage_Install $3 
				elif [[ -z "$3" ]]; then	
					Green_msg "So,you want to INSTALL PORTAGE INTO YOUR root? It is the default option (Y/N)"
					read ans
					case "$ans" in
						[yY]) 
							if [[ -w /usr ]]; then
							Portage_Install
						else
							Root_warn
							Red_msg "/usr dir is not writable, You may in a livecd envirenment"
							Red_msg "Sorry you cannot install Portage directory into you root"
							exit
						fi
							;;
						[nN]) exit ;;
						*) exit ;;
					esac
				else
					Red_msg "Please Inditify A Valid Directory To Install Portage"
					Help_msg
				fi
				exit ;;
			Uninstall)
				if [[ -d "$3" ]]; then
					Portage_Uninstall "$3"
				elif [[ -z "$3" ]]; then
					Red_msg "You are going to Uninstall portage from you previous ROOT.This is default Option(Y/n)"
					read choice
					case "$choice" in
						Y|y) ;;
						*) exit ;;
					esac
					Portage_Uninstall 
				fi
				exit 
				;;
			*) 
				Help_msg
				exit ;;
		esac
		;;
	Gentoo)
		case "$2" in
			Install)
				Green_msg "To Be Done"
				exit ;;
			Uninstall)
				Green_msg "To Be Done" 
				exit ;;
			*)
				exit;;
		esac
		;;
	*)
		exit ;;
esac
