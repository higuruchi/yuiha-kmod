#!/bin/bash +x

script_dir=$(cd $(dirname $0); pwd)

text_address=`cat /sys/module/ext3/sections/.text`
bss_address=`cat /sys/module/ext3/sections/.bss`
data_address=`cat /sys/module/ext3/sections/.data`

cat <<EOF > "${script_dir}/gdb_script"
directory ../fs/ext3
add-symbol-file ../fs/ext3/ext3.ko -s .text ${text_address} -s .bss ${bss_address} -s .data ${data_address}
EOF

sudo sh -c "echo ttyS1 > /sys/module/kgdboc/parameters/kgdboc"
sudo sh -c "echo g > /proc/sysrq-trigger"
