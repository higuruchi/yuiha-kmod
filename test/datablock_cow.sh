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
# Initialization process
#####################################################

set -e -o pipefail
trap 'err ${LINENO[0]} ${FUNCNAME[1]}' ERR

readonly MOUNT_POINT=$1
readonly YUIHA_UTIL_PATH=$2
readonly TEST_TARGET_FILE="cow_test"
readonly rw_block_size="1024"
# Direct reference datablock test
# 2-stage indirect reference datablock test
# 3-stage indirect reference datablock test
# 4-stage indirect reference datablock test
readonly rw_block_count=(
	# 1
	# 12
	# $((12+30))
	# $((12+256+10))
	$((12+256+256*256+2))
)

if [ ! -d "${MOUNT_POINT}" ]; then
	raise "${MOUNT_POINT} not found"	
fi

if [ ! -x "${YUIHA_UTIL_PATH}" ]; then
	raise "${YUIHA_UTIL_PATH} not found"
fi

if [ ! -f "${MOUNT_POINT}/${TEST_TARGET_FILE}" ]; then
	for bcount in "${rw_block_count[@]}"; do
		touch "${MOUNT_POINT}/${TEST_TARGET_FILE}_${bcount}.img"
	done
fi


for bcount in "${rw_block_count[@]}"; do
	echo "Writing ${TEST_TARGET_FILE}_${bcount}.img"
	dd if=/dev/zero of="${MOUNT_POINT}/${TEST_TARGET_FILE}_${bcount}.img" \
	 	bs=${rw_block_size} count=${bcount}
	${YUIHA_UTIL_PATH} --snapshot="${MOUNT_POINT}/${TEST_TARGET_FILE}_${bcount}.img"
	# dd if=/dev/urandom of="${MOUNT_POINT}/${TEST_TARGET_FILE}_${bcount}.img" \
	#	bs=1 count=1 obs=1 seek=$((bcount*rw_block_size-1)) conv=notrunc
	# dd if=/dev/urandom of="${MOUNT_POINT}/${TEST_TARGET_FILE}_${bcount}.img" \
	# 	bs=1 count=1 obs=1 seek=$((bcount*(rw_block_size-2)-1)) conv=notrunc
	dd if=/dev/zero of="${MOUNT_POINT}/${TEST_TARGET_FILE}_${bcount}.img" \
	 	bs=${rw_block_size} count=${bcount} conv=notrunc
	#dd if=/dev/urandom of="${MOUNT_POINT}/${TEST_TARGET_FILE}_${bcount}.img" \
	# 	bs=1 count=$((bcount*rw_block_size)) conv=notrunc
done

