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
	#append
	seq
	#rand
	#vmemu
)

append_size=(
	100
	1000
	10000
	100000
	200000
	100000
)

seq_size=(
	40k
	200k
	400k
	1M
	10M
	100M
	1g
)

rand_size=(
	200k
	2m
	20m
	200m
	1g
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
	20
	100
)

FS=${1:-"yuiha"}
if [ ! ${MODE} = "yuiha" ] && [ ! ${MODE} = "ext3" ] && [ ! ${MODE} = "nilfs" ]; then
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
				virsh snapshot-revert yuiha-perf rootpass
				sleep 10
				sudo sh -c "echo 2 > /proc/sys/vm/drop_caches"
				REMOTE_CMD="${MOUNT_CMD}; /home/master/mnt/YuihaFS/exp/perf.sh /home/master/mnt/YuihaFS/exp/log ${FS} $m $size 90 $span 1"
				echo $REMOTE_CMD
				bash -c "exec setsid ssh -oHostKeyAlgorithms=+ssh-dss $SSH_USER@$SSH_HOST '$REMOTE_CMD'"
			done
		done
	elif [ $m = "seq" ]; then
		for size in "${seq_size[@]}"
		do
			for span in "${ss_span[@]}"
			do
				virsh snapshot-revert yuiha-perf rootpass
				sleep 10
				sudo sh -c "echo 2 > /proc/sys/vm/drop_caches"
				REMOTE_CMD="${MOUNT_CMD}; /home/master/mnt/YuihaFS/exp/perf.sh /home/master/mnt/YuihaFS/exp/log ${FS} $m $size 90 $span 1"
				bash -c "exec setsid ssh -oHostKeyAlgorithms=+ssh-dss $SSH_USER@$SSH_HOST '$REMOTE_CMD'"
			done
		done
	elif [ $m = "rand" ]; then
		for size in "${rand_size[@]}"
		do
			for span in "${ss_span[@]}"
			do
				virsh snapshot-revert yuiha-perf rootpass
				sleep 10
				sudo sh -c "echo 2 > /proc/sys/vm/drop_caches"
				REMOTE_CMD="${MOUNT_CMD}; /home/master/mnt/YuihaFS/exp/perf.sh /home/master/mnt/YuihaFS/exp/log ${FS} $m $size 90 $span 1"
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
				sudo sh -c "echo 2 > /proc/sys/vm/drop_caches"
				REMOTE_CMD="${MOUNT_CMD}; /home/master/mnt/YuihaFS/exp/perf.sh /home/master/mnt/YuihaFS/exp/log ${FS} $m $size 50 $span 1"
				bash -c "exec setsid ssh -oHostKeyAlgorithms=+ssh-dss $SSH_USER@$SSH_HOST '$REMOTE_CMD'"
			done
		done
	fi
done

