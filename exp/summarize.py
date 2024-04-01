import csv
import os
import sys

directory = sys.argv[1]
filenames = os.listdir(directory)

for filename in filenames:
    f_split = filename.split('_')
    mode = f_split[0]
    size = f_split[2]
    loop = int(f_split[3])
    span = int(f_split[4])
    time=0
    if mode == "append":
        time = f_split[5][:len(f_split[5]) - 4]
    else:
        time = f_split[6][:len(f_split[5]) - 4]

    size_int = 0
    if size[-1:] == 'B':
        size_int = int(size[0:len(size) - 2])
        if size[-2] == 'K':
            size_int *= 1024
        elif size[-2] == 'M':
            size_int *= 1024
            size_int *= 1024
    elif size[-1:] == 'k' or size[-1:] == 'm' or size[-1:] == 'g':
        size_int = int(size[0:len(size) - 1])
        if size[-1:] == 'k':
            size_int *= 1024
        elif size[-1:] == 'm':
            size_int *= 1024
            size_int *= 1024
        elif size[-1:] == 'g':
            size_int *= 1024
            size_int *= 1024
            size_int *= 1024
    else:
        size_int = int(size[:])

    bw_sum = 0
    with open(os.path.join(directory, filename)) as file:
        if mode == "append":
            reader = csv.reader(file)
            header = next(reader)
            for row in reader:
                bw_sum += float(row[1])
        elif mode == "rand" or mode == "seq":
            for line in file:
                l_split = line.split(';')
                bw_sum += float(l_split[21]) * 1024

    print("{},{},{},{},{},{}".format(time, mode, size, loop, span, bw_sum / loop))


