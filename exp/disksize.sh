#!/bin/bash -x

FS=$1
COUNT=${2:-100}
DEV="/dev/vdb"
MOUNT_POINT="/home/${USER}/research"
EXP_MOUNT_POINT="/home/${USER}/exp_mnt"

YUIHA_KMOD_PATH="${MOUNT_POINT}/yuiha-kmod"
YUTIL_PATH="${MOUNT_POINT}/yutil/yutil"
DDD_PATH="${YUIHA_KMOD_PATH}/exp/ddd"
NILFS2_KMOD_PATH="${MOUNT_POINT}/nilfs2-kmod6"

sudo ntpdate ntp.nict.jp
exp_date=`date +"%Y-%m-%d_%H-%M-%S"`
LOGFILE_PATH="${YUIHA_KMOD_PATH}/exp/exp_data/${exp_date}_${FS}"
LOGFILE_NAME="yuiha_exp.csv"
IO_PATTERN_DIR_PATH="${YUIHA_KMOD_PATH}/exp"

mode=(
  append
  seq
)

append_size=(
	200KB
	400KB
  800KB
  1600KB
)

seq_size=(
  60k
  250k
  1000k
  4000k
  # 10000k
)

vmemu_size=(
	"start"
	"update"
)

ss_span=(
	1
	# 2
	# 5
	# 10
  # 200
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

  if [ ${FS} = "yuiha" ] ; then
		sudo mke2fs -F -t ext3 -I 256 -b 4096 ${DEV} > /dev/null 2>&1
  elif [ ${FS} = "nilfs2" ]; then
		sudo mkfs -t nilfs2 ${DEV} > /dev/null 2>&1
  elif [ ${FS} = "ext4" ]; then
		sudo mke2fs -F -t ext4 -I 256 -b 4096 ${DEV} > /dev/null 2>&1
  fi

	sudo mount -t ${FS} ${DEV} ${EXP_MOUNT_POINT}
  sudo chown ${USER}:${USER} ${EXP_MOUNT_POINT}
  before_img_size=`df | grep ${DEV} | awk '{print $3}'`

  echo $before_img_size
}

function exp_cleanup() {
  local mode=$1
  local size=$2
  local ss_span=$3
  local before_img_size=$4
  local mean_write_bw=$5

  after_img_size=`df --sync | grep ${DEV} | awk '{print $3}'`
  sudo umount ${EXP_MOUNT_POINT}
  diff_img_size=$(($after_img_size - $before_img_size))

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
	local TEST_NAME="seq_write"
	local FILE_NAME="${TEST_NAME}.1.0"
	local VMSTAT_LOG_FILE="${TEST_NAME}_vmstat.log"

	vmstat 1 >> "${LOGFILE_PATH}/${VMSTAT_LOG_FILE}" &
	local vmstat_pid=$!

	local bw_sum=0
	for i in `seq 1 ${COUNT}`; do
		local bw=`fio \
         --minimal \
         --rw=write \
         --numjobs=1 \
         --bs=${SEQ_WRITE_SIZE} \
         --directory=${EXP_MOUNT_POINT} \
         --size=${SEQ_WRITE_SIZE} \
         --overwrite=1 \
         --name="${TEST_NAME}" | \
         awk -F ";" 'NR%2==1 {printf "%d", $21 * 1024}'`
		bw_sum=`echo "scale=6; ${bw} + ${bw_sum}" | bc`

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} vc --path="${EXP_MOUNT_POINT}/${FILE_NAME}" \
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
	local APPEND_SIZE=$1
	local SS_SPAN=$2
  local CON_COUNT=1
	local TEST_NAME="append"
	local FILE_NAME="${TEST_NAME}.1.0"
	local VMSTAT_LOG_FILE="${TEST_NAME}_vmstat.log"

	vmstat 1 >> "${LOGFILE_PATH}/${VMSTAT_LOG_FILE}" &
	local vmstat_pid=$!

	local bw_sum=0
	for i in `seq 1 ${COUNT}`; do
		# local bw=`fio \
    #      --minimal \
    #      --rw=write \
    #      --numjobs=1 \
    #      --bs=${APPEND_SIZE} \
    #      --directory=${EXP_MOUNT_POINT} \
    #      --size=${APPEND_SIZE} \
    #      --overwrite=1 \
    #      --offset=$(((i - 1) * ${APPEND_SIZE})) \
    #      --name="${TEST_NAME}" | \
    #      awk -F ";" 'NR%2==1 {printf "%d", $21 * 1024}'`
		# bw_sum=`echo "scale=6; ${bw} + ${bw_sum}" | bc`
    dd \
      if=/dev/zero \
      of="${EXP_MOUNT_POINT}/${FILE_NAME}" \
      bs=${APPEND_SIZE} \
      count=1 \
      obs=${APPEND_SIZE} \
      seek=$((i-1))
    sync
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} vc --path="${EXP_MOUNT_POINT}/${FILE_NAME}" \
          > /dev/null 2>&1
			elif [ ${FS} = "nilfs2" ]; then
				sudo mkcp -s > /dev/null 2>&1
			fi
		fi
	done

	kill ${vmstat_pid}
  # local mean_bw=`echo "scale=6; ${bw_sum} / ${COUNT}" | bc`
	# echo ${mean_bw}
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
        before_img_size=$(exp_init)
        mean_write_bw=$(append_write_exp ${size} ${span})
        exp_cleanup ${m} ${size} ${span} ${before_img_size} ${mean_write_bw}
			done
		done
	elif [ $m = "seq" ]; then
		for size in "${seq_size[@]}"; do
			for span in "${ss_span[@]}"; do
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

