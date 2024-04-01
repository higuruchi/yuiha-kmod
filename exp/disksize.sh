#!/bin/bash

#####################################################
# Error Handling
#####################################################

# Cause an error
# $1: Error message string
function raise() {
	echo $1 1>&2
	return 1
}

err_buf=""
function err() {
  # Usage: trap 'err ${LINENO[0]} ${FUNCNAME[1]}' ERR
  status=$?
  lineno=$1
  func_name=${2:-main}
  err_str="ERROR: [`date +'%Y-%m-%d %H:%M:%S'`] ${SCRIPT}:${func_name}() \
	  returned non-zero exit status ${status} at line ${lineno}"
  echo ${err_str} 
  err_buf+=${err_str}
}

function init () {
	img_file=$1
	fs=$2

	if [ ! ${fs} = "yuiha" ] && [ ! ${fs} = "nilfs2" ]; then
		raise "Invalid filesystem: your input value is ${MODE}"
	fi

	mkdir yuiha_mnt

	if [ ${fs} = "nilfs2" ]; then
		sudo apt-get install -y nilfs2-tools
		cd /home/master/mnt/nilfs2-kmod6/ && make && sudo make install && \
		  sudo depmod -a && sudo modprobe -v ${fs} && cd /home/master
		sudo mkfs -t ${fs} /dev/vdb
		sudo mount -t ${fs} /dev/vdb /home/master/yuiha_mnt
	elif [ ${fs} = "yuiha" ]; then
		cd /home/master/mnt/YuihaFS && make && sudo make install && \
			sudo make load && cd /home/master
		sudo mke2fs -t ext3 -I 256 -b 4096 /dev/vdb
		sudo mount -t ${fs} /dev/vdb /home/master/yuiha_mnt
	fi

	sudo chown master:master /home/master/yuiha_mnt

	echo "/home/master/img/${img_file}"
}

#####################################################
# Over write experiment script
#####################################################
function over_write_exp () {
	OVER_WRITE_SIZE=${1:-8K}
	OVER_WRITE_COUNT=${2:-100}
	SS_SPAN=${3:-1}
	MOUNT_POINT=${4:-"."}
	YUTIL_PATH=${5:-"yutil"}
	FS=${6}

	FILE_NAME="over_write_size-${OVER_WRITE_SIZE}_count-${OVER_WRITE_COUNT}_ss-span-${SS_SPAN}.img"

	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
	 	raise "yutil command not found"
	 	return 1
	fi

	if [ -e "${MOUNT_POINT}/${FILE_NAME}" ]; then
		rm "${MOUNT_POINT}/${FILE_NAME}"
	fi

	for i in `seq 1 ${OVER_WRITE_COUNT}`; do
		echo "Overwrite ${i}"
		dd if=/dev/zero of="${MOUNT_POINT}/${FILE_NAME}" bs=${OVER_WRITE_SIZE} count=1 conv=notrunc

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			echo "Create SS ${i}"
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
			elif [ ${FS} = "nilfs2" ]; then
				sudo mkcp -s
			fi
		fi
	done
}

#####################################################
# Append write experiment script
#####################################################
function append_write_exp () {
	APPEND_SIZE=${1:-100}
	APPEND_COUNT=${2:-100}
	SS_SPAN=${3:-1}
	MOUNT_POINT=${4:-"."}
	YUTIL_PATH=${5:-"yutil"}
	FS=${6}

	FILE_NAME="append_write_size-${APPEND_SIZE}_count-${APPEND_COUNT}_ss-span-${SS_SPAN}.img"

	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
	 	raise "yutil command not found"
	 	return 1
	fi

	if [ -e "${MOUNT_POINT}/${FILE_NAME}" ]; then
		rm "${MOUNT_POINT}/${FILE_NAME}"
	fi

	for i in `seq 1 ${APPEND_COUNT}`; do
		echo "Append ${i}"
		dd if=/dev/zero of="${MOUNT_POINT}/${FILE_NAME}" bs=${APPEND_SIZE} count=1 \
			obs=${APPEND_SIZE} seek=$((i-1))

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			echo "Create SS ${i}"
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
			elif [ ${FS} = "nilfs2" ]; then
				sudo mkcp -s
			fi
		fi
	done
}

#####################################################
# Append write experiment script
#####################################################
function vmemu_write_exp () {
	VMEMU_KINDS=${1:-"start"}
	COUNT=${2:-100}
	SS_SPAN=${3:-1}
	MOUNT_POINT=${4:-"."}
	UTIL_PATH=${5:-"yutil"}
	DDD_PATH=${6:-"ddd"}
	IO_PATTERN_DIR_PATH=${7}
	FS=${8}

	FILE_NAME="vmimg.img"

	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
	 	raise "yutil command not found"
	 	return 1
	fi

	if !(type ${DDD_PATH} > /dev/null 2>&1); then
	 	raise "ddd command not found"
	 	return 1
	fi

	if [ ! -e "${IO_PATTERN_DIR_PATH}/vm_${VMEMU_KINDS}_disk_io.log" ]; then
	 	raise "${IO_PATTERN_DIR_PATH}/vm_${VMEMU_KINDS}_disk_io.log not found"
	 	return 1
	fi

	if [ -e "${MOUNT_POINT}/${FILE_NAME}" ]; then
		rm "${MOUNT_POINT}/${FILE_NAME}"
	fi


	for i in `seq 1 ${COUNT}`; do
		echo "vmemu ${VMEMU_KINDS} ${i}"
		${DDD_PATH} "${MOUNT_POINT}/${FILE_NAME}" < "${IO_PATTERN_DIR_PATH}/vm_${VMEMU_KINDS}_disk_io.log"

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			echo "Create SS ${i}"
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
			elif [ ${FS} = "nilfs2" ]; then
				sudo mkcp -s
			fi
		fi
	done
}

LOGFILE_PATH=${1:-"."}
MODE=${2:-"append"}
SIZE=${3:-100}
COUNT=${4:-100}
SS_SPAN=${5:-1}
FS=${6:-"yuiha"}

LOGFILE_NAME="yuiha_disksize_exp.csv"
MOUNT_POINT="/home/master/yuiha_mnt"
YUTIL_PATH="/home/master/mnt/YuihaFS-util/yutil"
DDD_PATH="/home/master/mnt/YuihaFS/exp/ddd"
IO_PATTERN_DIR_PATH="/home/master/mnt/YuihaFS/exp"

if [ ! -e "${LOGFILE_PATH}/${LOGFILE_NAME}" ]; then
	echo "date,mode,size,count,ss_span,fs,before_img_size,after_img_size,diff_img_size" \
		>> "${LOGFILE_PATH}/${LOGFILE_NAME}"
fi

if [ ! ${MODE} = "append" ] && [ ! ${MODE} = "over" ] && [ ! ${MODE} = "vmemu" ]; then
	raise "Invalid mode: your input value is ${MODE}"
fi

exp_date=`date +"%Y%m%d%H%M%S%3N"`
img_file="disksize_exp.img"

img_path=`init ${img_file} ${FS}`
echo $img_path

sync
#before_img_size=`du ${img_path} | sed -E "s/\t.*//g"`
before_img_size=`sudo df --sync /dev/vdb | awk '{print $3}' | tail -n 1`

if [ ${MODE} = "append" ] || [ ${MODE} = "over" ]; then
	"${MODE}_write_exp" ${SIZE} ${COUNT} ${SS_SPAN} ${MOUNT_POINT} ${YUTIL_PATH} ${FS}
elif [ ${MODE} = "vmemu" ]; then
	vmemu_write_exp ${SIZE} ${COUNT} ${SS_SPAN} ${MOUNT_POINT} \
	 	${YUTIL_PATH} ${DDD_PATH} ${IO_PATTERN_DIR_PATH} ${FS}
fi

sync
# after_img_size=`du ${img_path} | sed -E "s/\t.*//g"`
after_img_size=`sudo df --sync /dev/vdb | awk '{print $3}' | tail -n 1`
diff_img_size=$(($after_img_size - $before_img_size))

echo "${exp_date},${MODE},${SIZE},${COUNT},${SS_SPAN},${FS},${before_img_size},${after_img_size},${diff_img_size}" >> "${LOGFILE_PATH}/${LOGFILE_NAME}"

