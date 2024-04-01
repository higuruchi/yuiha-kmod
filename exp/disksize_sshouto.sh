#!/bin/bash

# 接続先情報
SSH_USER=root
SSH_PASS=password
SSH_HOST="192.168.122.113"

# 後述のSSH_ASKPASSで設定したプログラム(本ファイル自身)が返す内容
if [ -n "$PASSWORD" ]; then
	cat <<< $PASSWORD
	exit 0
fi

# SSH_ASKPASSで呼ばれるシェルにパスワードを渡すために変数を設定
export PASSWORD=$SSH_PASS

export SSH_ASKPASS=$0
export DISPLAY=dummy:0

mode=(
	append
	over
	#vmemu
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

over_size=(
	40KB
	200KB
	400KB
	1MB
	10MB
	100MB
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
	# 20
	# 100
)

FS=${1:-"yuiha"}
if [ ! ${MODE} = "yuiha" ] && [ ! ${MODE} = "nilfs2" ]; then
	raise "Invalid mode: your input value is ${MODE}"
fi

MOUNT_CMD="cd /home/master; mount -t nfs -vvvv -o nfsvers=3 192.168.0.104:/home/master/program/research /home/master/mnt"

for m in "${mode[@]}"
do
	if [ $m = "append" ]; then
		for size in "${append_size[@]}"
		do
			for span in "${ss_span[@]}"
			do
				virsh snapshot-revert yuiha-perf ddd
				sleep 10
				REMOTE_CMD="${MOUNT_CMD}; /home/master/mnt/YuihaFS/exp/disksize.sh /home/master/mnt/YuihaFS/exp $m $size 200 $span $FS"
				echo $REMOTE_CMD
				bash -c "exec setsid ssh -oHostKeyAlgorithms=+ssh-dss $SSH_USER@$SSH_HOST '$REMOTE_CMD'"
			done
		done
	elif [ $m = "over" ]; then
		for size in "${over_size[@]}"
		do
			for span in "${ss_span[@]}"
			do
				virsh snapshot-revert yuiha-perf ddd
				sleep 10
				REMOTE_CMD="${MOUNT_CMD}; /home/master/mnt/YuihaFS/exp/disksize.sh /home/master/mnt/YuihaFS/exp $m $size 200 $span $FS"
				bash -c "exec setsid ssh -oHostKeyAlgorithms=+ssh-dss $SSH_USER@$SSH_HOST '$REMOTE_CMD'"
			done
		done
	elif [ $m = "vmemu" ]; then
		for size in "${vmemu_size[@]}"
		do
			for span in "${ss_span[@]}"
			do
				virsh snapshot-revert yuiha-perf ddd
				sleep 10
				REMOTE_CMD="${MOUNT_CMD}; /home/master/mnt/YuihaFS/exp/disksize.sh /home/master/mnt/YuihaFS/exp $m $size 50 $span $FS"
				bash -c "exec setsid ssh -oHostKeyAlgorithms=+ssh-dss $SSH_USER@$SSH_HOST '$REMOTE_CMD'"
			done
		done
	fi
done

