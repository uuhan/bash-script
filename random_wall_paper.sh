#!/bin/bash

#确保只有一个程序
while [[ `ps aux |grep -E "[a-z]ash $0"|wc -l` != 2 ]]; do
	instancs=(`ps aux |grep -E "[a-z]ash $0"`)
	if [[ -n "${instancs[1]}" ]]; then
		kill -9 ${instancs[1]}

	fi
done
Green_msg(){
	echo -ne "[0;32m* $1\n[0;39m"
}
Red_msg(){
	echo -ne "[0;31m* $1\n[0;39m"
}
help_mag(){
	Green_msg "-o 指定feh的模式，默认为 --bg-scale"
	Green_msg "-D 指定图片文件夹（支持递归搜索，jpeg,png）默认为/opt/wallpaper/"
	Green_msg "-t 指定随机时间，默认为10(s)"
	Green_msg "   图片显示有以下的模式:"
	Green_msg "--bg-center: 图片不伸缩，居中显示"
	Green_msg "--bg-fill  : 填充整个桌面，拉伸图片"
	Green_msg "--bg-max   : 填充整个桌面，不拉伸图片"
	Green_msg "--bg-scale : 填充整个桌面， 同--bg-fill"
}
[[ -x `which feh` ]] || Red_msg "需要feh工具"
while getopts ":vho:D:t:" x; do
	case $x in
		o)
			feh_option=${OPTARG}
			;;
		D)
			wall_paper_dir=${OPTARG}
			if ! [[ -d "${wall_paper_dir}" ]]; then
				Red_msg "-D选项后面需要指定一个文件夹"
				exit 1
			fi
			;;
		t)
			random_time=${OPTARG}
			if ! ((OPTARG+=1)); then 
				Red_msg "请指定一个数字" 
				help_mag
				exit 1
			fi
			;;
		v)
			Green_msg "$0 version: 0.0.1"
			exit 0
			;;
		h)
			Green_msg "Usage: $0 -t [随机时间] -D [图片文件夹] -o [图片显示参数] -v [显示版本号] -h [显示本帮助]"
			help_mag
			exit 0
			;;
		:)
			Red_msg "缺少参数" >&2
			Green_msg "Usage: $0 -o -D -n"
			help_mag
			exit 1
			;;
		\?)
			Red_msg "无效选项 -${OPTARG}" >&2
			Green_msg "Usage: $0 -o -D -n"
			help_mag
			exit 1
			;;
	esac
done

: ${wall_paper_dir:="/opt/wallpaper/"}
: ${feh_option:='--bg-scale'}
if ! [[ ${wall_paper_dir} =~ /$ ]]; then
	wall_paper_dir="${wall_paper_dir}/"
fi

if ! [[ -e "${wall_paper_dir}" ]]; then
	echo "Wallpaper dir does not exist, Error"
	exit 1
fi

# 图片列表以及图片数量
pic_list=($(		
while read a; do
	if file $a |grep -iEq ": JPEG|: PNG"; then
		echo $a
	fi
done < <(find ${wall_paper_dir} -type f) 
))
pic_num=${#pic_list[@]}

if [[ -z ${pic_num} ]]; then Red_msg "No picture found in ${wall_paper_dir}"; fi
# Main
while true; do
	flag=$((${RANDOM}%${pic_num}))
	: ${old_flag:-$((${flag}+1))}

	if [[ ${flag} == ${old_flag} ]]; then
		continue
	else
		if feh ${feh_option} ${pic_list[${flag}]} &>/dev/null; then
			sleep ${random_time:-10}
		else
			break
		fi
	fi
	old_flag=${flag}
done
