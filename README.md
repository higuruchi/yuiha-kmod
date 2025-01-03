# YuihaFS

We designed and implemented new filesystem with novel snapshot function called YuihaFS. YuihaFS supports to create fine-grained snapshots; thus, YuihaFS allows users and applications to create a snapshot for each file at any time. Each file snapshot has a parent-child relationship, and each file snapshot is called a version. This allows users and applications to freely set whether creating a version or not and how often to create versions. Consequently, the users and applications can create a version depending on the importance of the file. Therefore, the necessary versions are only retained, and the disk usage can be reduced.

## Enviroment

- Distribution == Ubuntu10.04
- Linux Kernel == 2.6.32

### How to create VM of Ubuntu10.04 and debug it using kgdb

<!--
#### Libvirt

**VM creation**
```bash
$ virt-install \
  --name yuiha-vm \
  --ram 4096 \
  --disk path=<VM disk image path>,size=20 \
  --vcpus 2 \
  --os-variant=ubuntu10.04 \
  --network bridge=virbr0 \
  --graphics none \
  --console pty,target_type=serial \
  --location <Ubuntu10.04 iso file> \
  --extra-args 'console=ttyS0,115200n8 serial'
```


**Debuggee**
```bash
$ sed -e "s/GRUB_CMDLINE_LINUX_DEFAULT/GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0,115200 kgdboc=ttyS0,115200 nokaslr\"/" /etc/default/grub | sudo tee /etc/default/grub
```

**Debugger**
To modify the guest domain file, `virsh-edit` command is used.

```bash
$ virsh edit yuiha-vm
```

Find the `domain` directive and add the option `xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'`.

```xml
<domain type='kvm'
        xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0' >
```

Add a new `qemu:commandline` tag inside domain which will allow us to pass a parameter to QEMU for this guest when starting.

```xml
<domain type='kvm'
       xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0' >
     <qemu:commandline>
          <qemu:arg value='-s'/>
     </qemu:commandline>
```
-->

#### QEMU

**VM creation**
```
# Install Ubuntu10.04 to VM
$ qemu-system-x86_64 \
	-cpu host \
	-accel kvm \
	-boot c \
	-m 4G \
	-vga none \
	-nographic \
	-cdrom <Ubuntu10.04 iso file> \
	-drive file=<VM disk image path>,if=virtio

# Start VM
$ qemu-system-x86_64 \
	-cpu host \
	-smp 4 \
	-accel kvm \
	-m 4G \
	-boot d \
	-vga none \
	-nographic \
	-drive file=<VM disk file path>,if=virtio \
	-chardev pty,id=char0 \
	-serial chardev:char0 \
	-chardev pty,id=char1 \
	-serial chardev:char1 \
	-monitor unix:<vm unix socket path>,server,nowait
```

**Debuggee**

```
$ sudo sh -c "echo ttyS1 > /sys/module/kgdboc/parameters/kgdboc"
$ sudo sh -c "echo g > /proc/sysrq-trigger"
```

**Debugger**

Access to the terminal
```
$ picocom </dev/pts/*>
```

Using the kgdb
```
$ gdb <vmlinux path>
(gdb) target remote </dev/pts/*>
```

Acces to the QEMU monitor
```
$ socat - UNIX-CONNECT:<unix socket path>
```

### How to initialize build enviroment

```bash
$ sudo sed -i -e 's|//.*ubuntu.com/|//old-releases.ubuntu.com/|' /etc/apt/sources.list
$ sudo apt-get update
$ sudo apt-get install -y \
               nfs-common \
               libncurses-dev \
               openssh-server
$ Download Linux kernel source code of 2.6.32
$ cd linux-2.6.32
$ make -j2
$ sudo make modules_install && \
  sudo make install && \
  sudo mkinitramfs -o /boot/initrd.img-2.6.32 2.6.32
$ sed -e "s/GRUB_DEFAULT=0/GRUB_DEFAULT=\"Ubuntu, with Linux 2.6.32\"/" /etc/default/grub | sudo tee /etc/default/grub
$ sudo update-grub
$ sudo reboot
```

## How to build

```bash
$ make
```

## How to install

```bash
$ sudo make install
```

## How to load

```bash
$ sudo make load
```

## How to use

```bash
$ truncate -s 100M y.img && mkdir yuiha_mnt
$ sudo losetup /dev/loop0 y.img
$ sudo mke2fs -t ext3 -I 256 -b 4096 /dev/loop0
$ sudo mount -t yuiha /dev/loop0 ./yuiha_mnt
$ sudo chown master ./yuiha_mnt
$ echo fugafuga >> yuiha_mnt/hoge
$ yutil vc --path=./yuiha_mnt/hoge
$ echo mogemoge >> yuiha_mnt/hoge
$ cat yuiha_mnt/hoge
fugafuga
mogemoge
$ yutil cat -o --path=yuiha_mnt/hoge
fugafuga
```

`yutil` command command repository is https://github.com/higuruchi/yutil

### Check if backingstore state is correct

Block number and i-node number is different depending on execution time

```bash
# Show group discripter of group0
$ hexdump -C -v -s 4096 -n 32 y.img
00001000  08 00 00 00 09 00 00 00  0a 00 00 00 ae 59 f2 63  |.............Y.c|
00001010  02 00 04 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|

# Show child version inode
$ hexdump -C -v -s $((0x0a*4096+256*11)) -n 256 y.img
0000ab00  a4 81 e8 03 12 00 00 00  49 b8 44 66 32 b8 44 66  |........I.Df2.Df|
0000ab10  32 b8 44 66 00 00 00 00  e8 03 03 00 10 00 00 00  |2.Df............|
0000ab20  00 00 00 00 00 00 00 00  01 40 00 80 00 00 00 00  |.........@......|
0000ab30  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ab40  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ab50  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ab60  00 00 00 00 7c 00 d7 4e  00 00 00 00 00 00 00 00  |....|..N........|
0000ab70  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ab80  04 00 00 00 0e 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ab90  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000aba0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000abb0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000abc0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000abd0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000abe0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000abf0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ac00

# Show child version data block
$ hexdump -C -v -s $((0x4001*4096)) -n 256 y.img
04001000  66 75 67 61 66 75 67 61  0a 6d 6f 67 65 6d 6f 67  |fugafuga.mogemog|
04001010  65 0a 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |e...............|
04001020  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001030  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001040  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001050  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001060  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001070  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001080  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001090  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040010a0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040010b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040010c0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040010d0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040010e0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040010f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04001100

# Show parent version inode
$ hexdump -C -v -s $((0x0a*4096+256*12)) -n 256 y.img
0000ac00  a4 81 e8 03 09 00 00 00  1b b8 44 66 1b b8 44 66  |..........Df..Df|
0000ac10  1b b8 44 66 00 00 00 00  e8 03 01 00 08 00 00 00  |..Df............|
0000ac20  00 00 00 00 00 00 00 00  00 40 00 80 00 00 00 00  |.........@......|
0000ac30  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ac40  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ac50  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ac60  00 00 00 00 7c 00 d7 4e  00 00 00 00 00 00 00 00  |....|..N........|
0000ac70  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ac80  04 00 00 00 00 00 00 00  00 00 00 00 0e 00 00 00  |................|
0000ac90  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000aca0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000acb0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000acc0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000acd0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ace0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000acf0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0000ad00

# Show parent version data block
$ hexdump -C -v -s $((0x4000*4096)) -n 256 y.img
04000000  66 75 67 61 66 75 67 61  0a 00 00 00 00 00 00 00  |fugafuga........|
04000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000020  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000030  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000040  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000050  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000060  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000070  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000080  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000090  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040000a0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040000b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040000c0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040000d0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040000e0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
040000f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
04000100
```

