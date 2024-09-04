#!/bin/bash -x

exp_data_path=$1
base_dirname=`dirname ${exp_data_path}`
filename=`basename ${exp_data_path} | sed 's/\.[^\.]*$//' | sed 's/\.[^\.]*$//'`
blkparse -i ${exp_data_path} -a write -t -f "%a,%S,%n,%N,%5T.%9t,%z\n" | \
	grep Q, | \
	uniq | \
	sed -e '/Q,0,0,0/d' > "${base_dirname}/${filename}.csv"
./disk_io_sum.py "${base_dirname}/${filename}.csv" > "${base_dirname}/${filename}_iomap.csv"
