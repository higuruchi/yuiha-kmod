#!/bin/bash -x

FS=$1
COUNT=${2:-100}
DEV="/dev/vdb"
MOUNT_POINT="/home/${USER}/research"
EXP_MOUNT_POINT="/home/${USER}/exp_mnt"
EXP_IMG_FILE_PATH="${EXP_MOUNT_POINT}/exp_file.img"
LOOP_BACK_DEV="/dev/loop7"
LOOP_BACK_MOUNT_POINT="/home/${USER}/exp_loop_back_mnt"

YUIHA_KMOD_PATH="${MOUNT_POINT}/yuiha-kmod"
YUTIL_PATH="${MOUNT_POINT}/yutil/yutil"
DDD_PATH="${YUIHA_KMOD_PATH}/exp/ddd"
NILFS2_KMOD_PATH="${MOUNT_POINT}/nilfs2-kmod6"

exp_date=`date +"%Y-%m-%d_%H-%M"`
LOGFILE_PATH="${YUIHA_KMOD_PATH}/exp/exp_data/${exp_date}_${FS}"
LOGFILE_NAME="yuiha_exp.csv"
IO_PATTERN_DIR_PATH="${YUIHA_KMOD_PATH}/exp"

mode=(
	# append
  seq
)

append_size=(
	100
	1KB
	10KB
	100KB
	200KB
	300KB
	400KB
	500KB
	600KB
	700KB
	800KB
	1MB
)

seq_size=(
	# 40k
  # 160k
  # 640k
  # 2660k
  4200k
	# 9760k
  # 39040k
  # 40KB
  # 160KB
  # 640KB
  # 2660KB
  # 10640KB
)

vmemu_size=(
	"start"
	"update"
)

ss_span=(
	1
	2
	5
	10
)

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
  mkdir -p ${LOGFILE_PATH}

  if [ ! -d "${EXP_MOUNT_POINT}" ]; then
    mkdir ${EXP_MOUNT_POINT}
  fi

  if [ ! -d "${LOOP_BACK_MOUNT_POINT}" ]; then
    mkdir ${LOOP_BACK_MOUNT_POINT}
  fi

  if [ ! -e "${LOGFILE_PATH}/${LOGFILE_NAME}" ]; then
  	echo "date,mode,size,count,ss_span,fs,before_img_size,\
after_img_size,diff_img_size,mean_write_bw" >> "${LOGFILE_PATH}/${LOGFILE_NAME}"
  fi

  sudo apt-get install -y fio bc

  yuiha_exists_flg=`cat /proc/filesystems | grep yuiha | wc -l`
  nilfs2_exists_flg=`cat /proc/filesystems | grep nilfs2 | wc -l`

  if [ ${yuiha_exists_flg} -le 0 ]; then
		make --directory=${YUIHA_KMOD_PATH} && \
    sudo make --directory=${YUIHA_KMOD_PATH} install && \
		sudo make --directory=${YUIHA_KMOD_PATH} load
    # ${YUIHA_KMOD_PATH}/debug/gen_gdb_script.sh
	fi

	if  [ ${nilfs2_exists_flg} -le 0 ]; then
		sudo apt-get install -y nilfs2-tools
		make --directory=${NILFS2_KMOD_PATH} && \
    sudo make --directory=${NILFS2_KMOD_PATH} install && \
		sudo depmod -a && \
    sudo modprobe -v nilfs2
  fi
}

function exp_init() {

  if mountpoint -q ${LOOP_BACK_MOUNT_POINT}; then
    sudo umount ${LOOP_BACK_MOUNT_POINT}
    sudo losetup -d ${LOOP_BACK_DEV}
    rm ${EXP_IMG_FILE_PATH}
  fi

  # if [ ${EXP} = "perf" ]; then
  #   if [ ${FS} = "yuiha" ] || [${FS} = "ext3" ]; then
	#   	sudo mke2fs -t ext3 -I 256 -b 4096 ${DEV} > /dev/null 2>&1
  #   elif [ ${FS} = "nilfs2" ]; then
	#   	sudo mke2fs -t ${FS} ${DEV} > /dev/null 2>&1
  #   fi
  # elif [ ${EXP} = "size" ]; then
  #   sudo mk2fs -t ext4 ${DEV} > /dev/null 2>&1
  #   sudo mount -t ext4 ${DEV} ${EXP_MOUNT_POINT}
  #   truncate -s 10G 
  # fi

  if mountpoint -q ${EXP_MOUNT_POINT}; then
    sudo mk2fs -t ext4 ${DEV} > /dev/null 2>&1
    sudo mount -t ext4 ${DEV} ${EXP_MOUNT_POINT}
  fi

  truncate -s 100G ${EXP_IMG_FILE_PATH}
  sudo losetup ${LOOP_BACK_DEV} ${EXP_IMG_FILE_PATH}

  if [ ${FS} = "yuiha" ] || [${FS} = "ext3" ]; then
		sudo mke2fs -t ext3 -I 256 -b 4096 ${LOOP_BACK_DEV} > /dev/null 2>&1
  elif [ ${FS} = "nilfs2" ]; then
		sudo mke2fs -t nilfs2 ${LOOP_BACK_DEV} > /dev/null 2>&1
  fi

	sudo mount -t ${FS} ${LOOP_BACK_DEV} ${LOOP_BACK_MOUNT_POINT}
  sudo chown ${USER}:${USER} ${LOOP_BACK_MOUNT_POINT}
  # before_img_size=`du ${EXP_IMG_FILE_PATH} | awk '{print $1}'`
  before_img_size=`df | grep ${LOOP_BACK_DEV} | awk '{print $3}'`

  echo $before_img_size
}

function exp_cleanup() {
  local mode=$1
  local size=$2
  local ss_span=$3
  local before_img_size=$4
  local mean_write_bw=$5


  after_img_size=`df | grep ${LOOP_BACK_DEV} | awk '{print $3}'`
  sudo umount ${LOOP_BACK_MOUNT_POINT}
  sudo losetup -d ${LOOP_BACK_DEV}
  #after_img_size=`du ${EXP_IMG_FILE_PATH} | awk '{print $1}'`
  diff_img_size=$(($after_img_size - $before_img_size))
  rm ${EXP_IMG_FILE_PATH}

  echo "${exp_date},\
${mode},\
${size},\
${COUNT},\
${ss_span},\
${FS},\
${before_img_size},\
${after_img_size},\
${diff_img_size},\
${mean_write_bw}" >> "${LOGFILE_PATH}/${LOGFILE_NAME}"
}

#####################################################
# Sequential write experiment script
#####################################################
function seq_write_exp () {
	local SEQ_WRITE_SIZE=$1
	local SS_SPAN=$2

  local CON_COUNT=1
	local TEST_NAME="seq_${SEQ_WRITE_SIZE}_${COUNT}_${SS_SPAN}_${CON_COUNT}"
	local FILE_NAME="${TEST_NAME}.1.0"
	local VMSTAT_LOG_FILE="${TEST_NAME}_vmstat.log"

	vmstat 1 >> "${LOGFILE_PATH}/${VMSTAT_LOG_FILE}" &
	local vmstat_pid=$!

	local bw_sum=0
	for i in `seq 1 ${COUNT}`; do
		local bw=`fio \
         --minimal \
         --rw=write \
         --numjobs=${CON_COUNT} \
         --bs=4k \
         --directory=${LOOP_BACK_MOUNT_POINT} \
         --size=${SEQ_WRITE_SIZE} \
         --overwrite=1 \
         --name=${TEST_NAME} | \
         awk -F ";" 'NR%2==1 {printf "%d", $21 * 1024}'`
		bw_sum=`echo "scale=6; ${bw} + ${bw_sum}" | bc`
    # dd \
    #   if=/dev/zero \
    #   of="${LOOP_BACK_MOUNT_POINT}/${FILE_NAME}" \
    #   bs=${SEQ_WRITE_SIZE} \
    #   count=1 \
    #   conv=notrunc

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} vc --path="${LOOP_BACK_MOUNT_POINT}/${FILE_NAME}" \
          > /dev/null 2>&1
			elif [ ${FS} = "nilfs2" ]; then
				sudo mkcp -s > /dev/null 2>&1
			fi
		fi
	done

	kill ${vmstat_pid}
  local mean_bw=`echo "scale=6; ${bw_sum} / ${COUNT}" | bc`
	echo ${mean_bw}
}

#####################################################
# Append write experiment script
#####################################################
function append_write_exp () {
	APPEND_SIZE=${1:-100}
	SS_SPAN=${2:-1}

	FILE_NAME="append_write_size-${APPEND_SIZE}_count-${COUNT}_ss-span-${SS_SPAN}.img"

	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
	 	raise "yutil command not found"
	 	return 1
	fi

	if [ -e "${MOUNT_POINT}/${FILE_NAME}" ]; then
		rm "${MOUNT_POINT}/${FILE_NAME}"
	fi

	for i in `seq 1 ${COUNT}`; do
		dd \
      if=/dev/zero \
      of="${MOUNT_POINT}/${FILE_NAME}" \
      bs=${APPEND_SIZE} \
      count=1 \
			obs=${APPEND_SIZE} \
      seek=$((i-1))

		if [ $((i%SS_SPAN)) -eq 0 ]; then
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
# function vmemu_write_exp () {
# 	VMEMU_KINDS=${1:-"start"}
# 	COUNT=${2:-100}
# 	SS_SPAN=${3:-1}
# 	MOUNT_POINT=${4:-"."}
# 	UTIL_PATH=${5:-"yutil"}
# 	DDD_PATH=${6:-"ddd"}
# 	IO_PATTERN_DIR_PATH=${7}
# 	FS=${8}
# 
# 	FILE_NAME="vmimg.img"
# 
# 	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
# 	 	raise "yutil command not found"
# 	 	return 1
# 	fi
# 
# 	if !(type ${DDD_PATH} > /dev/null 2>&1); then
# 	 	raise "ddd command not found"
# 	 	return 1
# 	fi
# 
# 	if [ ! -e "${IO_PATTERN_DIR_PATH}/vm_${VMEMU_KINDS}_disk_io.log" ]; then
# 	 	raise "${IO_PATTERN_DIR_PATH}/vm_${VMEMU_KINDS}_disk_io.log not found"
# 	 	return 1
# 	fi
# 
# 	if [ -e "${MOUNT_POINT}/${FILE_NAME}" ]; then
# 		rm "${MOUNT_POINT}/${FILE_NAME}"
# 	fi
# 
# 
# 	for i in `seq 1 ${COUNT}`; do
# 		echo "vmemu ${VMEMU_KINDS} ${i}"
# 		${DDD_PATH} "${MOUNT_POINT}/${FILE_NAME}" < "${IO_PATTERN_DIR_PATH}/vm_${VMEMU_KINDS}_disk_io.log"
# 
# 		if [ $((i%SS_SPAN)) -eq 0 ]; then
# 			echo "Create SS ${i}"
# 			if [ ${FS} = "yuiha" ]; then
# 				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
# 			elif [ ${FS} = "nilfs2" ]; then
# 				sudo mkcp -s
# 			fi
# 		fi
# 	done
# }

init

for m in "${mode[@]}"; do
	if [ $m = "append" ]; then
		for size in "${append_size[@]}"; do
			for span in "${ss_span[@]}"; do
        echo hoge
			done
		done
	elif [ $m = "seq" ]; then
		for size in "${seq_size[@]}"; do
			for span in "${ss_span[@]}"; do
        echo $span
        before_img_size=$(exp_init)
        mean_write_bw=$(seq_write_exp ${size} ${span})
        exp_cleanup ${m} ${size} ${span} ${before_img_size} ${mean_write_bw}
			done
		done
	elif [ $m = "vmemu" ]; then
		for size in "${vmemu_size[@]}"; do
			for span in "${ss_span[@]}"; do
        echo fuga
			done
		done
	fi
done

