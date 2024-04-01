#!/bin/bash

VD_PATH=${1}
VM_NAME=${2:-"yuiha-perf"}
ADD_SIZE=${3:-"5G"}
VD_DEV=${4:-"sdc"}

if [ ${VD_PATH} = "" ] || [ ! -e ${VD_PATH} ]; then
	echo "VD_PATH not found"
	exit 0
fi

# 空の仮想ディスク作成
VD_FILE=${VM_NAME}-${VD_DEV}.qcow2
cd ${VD_PATH}
if [ -f ${VD_FILE} ]; then
   echo "${VD_FILE} : already exists"
   exit 1
fi
qemu-img create -f qcow2 ${VD_FILE} ${ADD_SIZE}

# オンラインで仮想マシンに接続
virsh attach-device ${VM_NAME} <(cat <<EOF
<disk type='file' device='disk'>
   <driver name='qemu' type='qcow2' cache='none'/>
   <source file='${VD_PATH}/${VD_FILE}'/>
   <target dev='${VD_DEV}' bus='virtio'/>
</disk>
EOF
)
 
# 設定の永続化
virsh attach-device ${VM_NAME} --config <(cat <<EOF
<disk type='file' device='disk'>
   <driver name='qemu' type='qcow2' cache='none'/>
   <source file='${VD_PATH}/${VD_FILE}'/>
   <target dev='${VD_DEV}' bus='virtio'/>
</disk>
EOF
)
 
exit 0
