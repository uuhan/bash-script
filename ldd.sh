#!/bin/bash
#Broken lib fix
for lib in `ldd ${1} 2>/dev/null |cut -d'>' -f2 |cut -d'(' -f1`; do
	if [[ ! -e ${lib#*/} && -e ${lib} ]]; then
		readlink $lib &>/dev/null || cp ${lib} ${lib#*/}
		readlink $lib &>/dev/null && \
		{
		cp ${lib%/*}/`readlink ${lib}` `dirname ${lib#*/}` && \
		ln -sv `readlink ${lib}` ${lib#*/}
		}
	elif [[ "$lib" == /* ]]; then
		echo ${lib#*/}:Exist
	else
		echo ${1}:$lib
	fi
done
