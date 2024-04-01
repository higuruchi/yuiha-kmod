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

#####################################################
# Initialization function
#####################################################
function init () {
	fs=$1
	ret=0

	if [ ! ${fs} = "ext3" -a ! ${fs} = "yuiha" ]; then
		ret=1
		raise "Invalid filesystem ${fs}"
		return $ret
	fi

	cd mnt/YuihaFS && make && sudo make install && sudo make load && cd /home/master
	sudo mke2fs -t ext3 -I 256 -b 4096 /dev/vdb
	mkdir yuiha_mnt

	if [ ${fs} = "ext3" ]; then
		sudo mount -t ext3 /dev/vdb ./yuiha_mnt
	elif [ ${fs} = "yuiha" ]; then
		sudo mount -t yuiha /dev/vdb ./yuiha_mnt
	fi

	sudo chown master:master ./yuiha_mnt

	sudo sh -c '(echo noop > /sys/block/vdb/queue/scheduler)'
	sudo sh -c '(echo 1 > /sys/block/vdb/queue/nomerges)'

	return $ret
}

function check_requirements () {
	ret=0
	DDD_PATH=$1

	if !(type fio > /dev/null 2>&1); then
		ret=1
		raise "fio command not found"
	fi

	if !(type bc > /dev/null 2>&1); then
		ret=1
		raise "bc command not found"
	fi
	
	if [ ! -x ${DDD_PATH} ]; then
		gcc -o ${DDD_PATH} "${DDD_PATH}.c"
	fi

	return $ret
}

#####################################################
# Sequential write performance experiment function
#####################################################
function seq_write_perf_exp () {
	SEQ_WRITE_SIZE=${1:-8k}
	SEQ_WRITE_COUNT=${2:-100}
	SS_SPAN=${3:-1}
	CON_COUNT=${4:-1}
	MOUNT_POINT=${5:-"."}
	YUTIL_PATH=${6:-"yutil"}
	LOG_FILE_PATH=${7:-"."}
	EXP_DATE=${8:-0}
	FS=${9:-"yuiha"}

	TEST_NAME="seq_${SEQ_WRITE_SIZE}_${SEQ_WRITE_COUNT}_${SS_SPAN}_${CON_COUNT}"
	#LOG_FILE="${TEST_NAME}_${EXP_DATE}.csv"
	FILE_NAME="${TEST_NAME}.1.0"

	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
	 	raise "yutil command not found"
	 	return 1
	fi

	VMSTAT_LOG_FILE="${TEST_NAME}_${EXP_DATE}_vmstat.log"
	vmstat 1 >> "${LOG_FILE_PATH}/${VMSTAT_LOG_FILE}" &
	vmstat_pid=$!

	bw_sum=0
	for i in `seq 1 ${SEQ_WRITE_COUNT}`; do
		bw=`fio --minimal --rw=write --numjobs=${CON_COUNT} --directory=${MOUNT_POINT} \
				--bs=4k --size=${SEQ_WRITE_SIZE} --name=${TEST_NAME} | \
				awk -F ";" 'NR%2==1 {printf "%d", $21 * 1024}'`
		bw_sum=`echo "scale=6; ${bw} + ${bw_sum}" | bc`

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
			fi
		fi
	done

	kill ${vmstat_pid}
	echo "scale=6; ${bw_sum} / ${SEQ_WRITE_COUNT}" | bc
}

#####################################################
# Random write performance experiment function
#####################################################
function rand_write_perf_exp () {
	RAND_WRITE_SIZE=${1:-8k}
	RAND_WRITE_COUNT=${2:-100}
	SS_SPAN=${3:-1}
	CON_COUNT=${4:-1}
	MOUNT_POINT=${5:-"."}
	YUTIL_PATH=${6:-"yutil"}
	LOG_FILE_PATH=${7:-"."}
	EXP_DATE=${8:-0}

	TEST_NAME="rand_write_${RAND_WRITE_SIZE}_${RAND_WRITE_COUNT}_${SS_SPAN}_${CON_COUNT}"
	LOG_FILE="${TEST_NAME}_${EXP_DATE}.csv"

	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
	 	raise "yutil command not found"
	 	return 1
	fi

	for i in `seq 1 ${RAND_WRITE_COUNT}`; do
		echo "randome write ${i}"

		fio_output=`fio --minimal --rw=randwrite --numjobs=${CON_COUNT} --directory=${MOUNT_POINT} \
			--bs=4k --size="${RAND_WRITE_SIZE}" --name=${TEST_NAME}`
		echo "${i};${fio_output}" >> "${LOG_FILE_PATH}/${LOG_FILE}"

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
			fi
		fi
	done

	echo "${LOG_FILE_PATH}/${LOG_FILE}"
}

#####################################################
# Append write performance experiment function
#####################################################
function append_write_perf_exp () {
	APPEND_SIZE=${1:-100}
	APPEND_COUNT=${2:-100}
	SS_SPAN=${3:-1}
	MOUNT_POINT=${4:-"."}
	YUTIL_PATH=${5:-"yutil"}
	LOG_FILE_PATH=${6:-"."}
	EXP_DATE=${7:-0}
	FS=${8:-"yuiha"}

	FILE_NAME="append_write.img"
	TEST_NAME="append_${FS}_${APPEND_SIZE}_${APPEND_COUNT}_${SS_SPAN}"

	if !(type ${YUTIL_PATH} > /dev/null 2>&1); then
	 	raise "yutil command not found"
	 	return 1
	fi

	if [ -e "${MOUNT_POINT}/${FILE_NAME}" ]; then
		rm "${MOUNT_POINT}/${FILE_NAME}"
	fi

	VMSTAT_LOG_FILE="${TEST_NAME}_${EXP_DATE}_vmstat.log"

	vmstat 1 >> "${LOG_FILE_PATH}/${VMSTAT_LOG_FILE}" &
	vmstat_pid=`echo $!`

	bw_sum=0
	for i in `seq 1 ${APPEND_COUNT}`; do

		bw=`${DDD_PATH} "${MOUNT_POINT}/${FILE_NAME}" "append=${APPEND_SIZE}" | awk '{print $1}'`
		bw_sum=`echo "scale=6; ${bw} + ${bw_sum}" | bc`

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
			fi
		fi
	done

	kill ${vmstat_pid}
	echo "scale=6; ${bw_sum} / ${APPEND_COUNT}" | bc
}

#####################################################
# VM emulate write performance experiment function
#####################################################
function vmemu_write_perf_exp () {
	VMEMU_KINDS=${1:-"start"}
	COUNT=${2:-100}
	SS_SPAN=${3:-1}
	MOUNT_POINT=${4:-"."}
	YUTIL_PATH=${5:-"yutil"}
	LOG_FILE_PATH=${6:-"."}
	EXP_DATE=${7:-0}
	IO_PATTERN_DIR_PATH=${8}
	DDD_PATH=${9}
	FS=${10}

	FILE_NAME="vm_write.img"
	TEST_NAME="vm_${VMEMU_KINDS}_${FS}"
	LOG_FILE="${TEST_NAME}_${EXP_DATE}.log"
	VMSTAT_LOG_FILE="${TEST_NAME}_${EXP_DATE}_vmstat.log"

	vmstat 1 >> "${LOG_FILE_PATH}/${VMSTAT_LOG_FILE}" &
	vmstat_pid=$!

	bw_sum=0
	for i in `seq 1 ${COUNT}`; do
		bw=`${DDD_PATH} "${MOUNT_POINT}/${FILE_NAME}" < "${IO_PATTERN_DIR_PATH}/vm_${VMEMU_KINDS}_disk_io.log" | \
				awk '{printf "%d", $1}'`
		bw_sum=`echo "scale=6; ${bw} + ${bw_sum}" | bc`

		if [ $((i%SS_SPAN)) -eq 0 ]; then
			if [ ${FS} = "yuiha" ]; then
				${YUTIL_PATH} --snapshot="${MOUNT_POINT}/${FILE_NAME}"
			fi
		fi
	done

	kill ${vmstat_pid}
	echo "scale=6; ${bw_sum} / ${COUNT}" | bc
}

LOGFILE_PATH=${1:-"."}
FS=${2:-"yuiha"}
MODE=${3:-"append"}
if [ ! ${MODE} = "append" ] && [ ! ${MODE} = "seq" ] && [ ! ${MODE} = "rand" ] && \ 
	[ ! ${MODE} = "vmemu" ]; then
	raise "Invalid mode: your input value is ${MODE}"
fi

SIZE=${4:-100}
COUNT=${5:-100}
SS_SPAN=${6:-1}
CON_COUNT=${7:-1}

LOGFILE_NAME="yuiha_perf_exp.csv"
MOUNT_POINT="/home/master/yuiha_mnt"
YUTIL_PATH="/home/master/mnt/YuihaFS-util/yutil"
DDD_PATH="/home/master/mnt/YuihaFS/exp/ddd"
IO_PATTERN_DIR_PATH="/home/master/mnt/YuihaFS/exp"

if [ ! -e "${LOGFILE_PATH}/${LOGFILE_NAME}" ]; then
	echo "date,mode,size,count,ss_span,fs,throughput(B/s)" \
		>> "${LOGFILE_PATH}/${LOGFILE_NAME}"
fi

set -e -o pipefail
trap 'err ${LINENO[0]} ${FUNCNAME[1]}' ERR

exp_date=`date +"%Y%m%d%H%M%S%3N"`

cd /home/master
check_requirements ${DDD_PATH}
if [ $? -ne 0 ]; then
	exit 1
fi

init ${FS}
if [ $? -ne 0 ]; then
	exit 1
fi

# Free page cache
sudo sh -c "echo 2 > /proc/sys/vm/drop_caches"

if [ ${MODE} = "seq" ] || [ ${MODE} = "rand" ]; then
	# seq write experiment and rand write experiment
	bw=`"${MODE}_write_perf_exp" ${SIZE} ${COUNT} ${SS_SPAN} ${CON_COUNT} ${MOUNT_POINT} \
		${YUTIL_PATH} ${LOGFILE_PATH} ${exp_date} ${FS}`
elif [ ${MODE} = "append" ]; then
	# append write experiment
	bw=`"${MODE}_write_perf_exp" ${SIZE} ${COUNT} ${SS_SPAN} ${MOUNT_POINT} ${YUTIL_PATH} \
		${LOGFILE_PATH} ${exp_date} ${FS}`
elif [ ${MODE} = "vmemu" ]; then
	# vmemu write experiment
	bw=`"${MODE}_write_perf_exp" ${SIZE} ${COUNT} ${SS_SPAN} ${MOUNT_POINT} ${YUTIL_PATH} \
		${LOGFILE_PATH} ${exp_date} ${IO_PATTERN_DIR_PATH} ${DDD_PATH} ${FS}`
fi

echo "${exp_date},${MODE},${SIZE},${COUNT},${SS_SPAN},${FS},${bw}" >> "${LOGFILE_PATH}/${LOGFILE_NAME}"
exit 0
