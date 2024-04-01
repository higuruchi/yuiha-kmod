
#!/bin/bash

vm_name=${1}

if [ -z "${vm_name}" ]; then
	echo "vm_name is required"
  exit 1
fi

img_name="jammy-server-cloudimg-amd64.img"
img_url="https://cloud-images.ubuntu.com/jammy/current/${img_name}"
img_path="/home/images"

if [ ! -e "${img_path}/${img_name}" ]; then
	curl -L "${img_url}" -o "${img_path}/${img_name}"
fi

sudo qemu-img create \
		-f qcow2 \
		-b "${img_path}/${img_name}" \
		-F qcow2 /var/lib/libvirt/images/${vm_name}.qcow2 20G

sudo qemu-img create \
		-f qcow2 \
		/var/lib/libvirt/images/${vm_name}_data.qcow2 20G

sudo mkisofs \
		-o /var/lib/libvirt/images/${vm_name}.iso \
		-V cidata \
		-R user-data meta-data

virt-install \
  --name ${vm_name} \
  --vcpus 2 \
  --ram 4096 \
  --virt-type kvm \
  --os-variant ubuntu22.04 \
  --graphics none --serial pty --console pty \
  --import \
  --disk path=/var/lib/libvirt/images/${vm_name}.qcow2 \
  --disk path=/var/lib/libvirt/images/${vm_name}_data.qcow2 \
  --disk path=/var/lib/libvirt/images/${vm_name}.iso,device=cdrom \
  --network network=host-bridge \
  --sysinfo system.serial='ds=nocloud'
