#!/usr/bin/env python3

import sys
import os
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter
import numpy as np

args = sys.argv
log_path = args[1]
diskio_logs = pd.read_csv(log_path, header=None)

def calc_disk_io_cumulative_sum():
    lba_digits = 8
    lba_arr_count = (6*10**(lba_digits - 1)) + 1
    lba_index = [0] * lba_arr_count
    lba_imos = [0] * lba_arr_count
    lba_sum = [0] * lba_arr_count
    
    lba_graph_index = []
    lba_graph_sum = []
    
    for i, l in diskio_logs.iterrows():
        lba_imos[l[1] // 10] += 1
        if l[2] // 10 == 0:
            lba_imos[l[1] // 10 + 1] -= 1
        else:
            lba_imos[(l[1] + l[2]) // 10] -= 1
    
    lba_sum[0] = lba_imos[0]
    print("lba_start,lba_end,count");
    for i in range(1, lba_arr_count):
        lba_index[i] = i
        lba_sum[i] = lba_sum[i - 1] + lba_imos[i]
        if lba_sum[i] != 0:
            lba_graph_index.append(i)
            lba_graph_sum.append(lba_sum[i])
            print("{},{},{}".format(i*10, i*10+9, lba_sum[i]));

def setup_fig(ax, data, time_max):
    min_lba = min(data[0])
    max_lba = max(data[0])

    ax.scatter(data[1], data[0], s=2)
    ax.set_xlabel("time(s)")
    ax.set_ylabel("lba")
    ax.set_xlim(0, time_max)
    ax.set_ylim(min_lba-10000, max_lba+10000)
    ax.yaxis.set_major_formatter(ScalarFormatter(useMathText=True))
    ax.ticklabel_format(style="sci", axis="y", scilimits=(6,6))

def gen_disk_io_scatter_plot():
    dirname, _ = os.path.split(log_path)
    filename_without_ext = os.path.splitext(os.path.basename(log_path))[0]

    lba_max = max(diskio_logs[1])
    middle = lba_max // 2
    
    low_disk_io = [[] for _ in range(2)]
    high_disk_io = [[] for _ in range(2)]

    for lba, time in zip(diskio_logs[1], diskio_logs[4]):
        if lba < middle:
            low_disk_io[0].append(lba)
            low_disk_io[1].append(time)
        else:
            high_disk_io[0].append(lba)
            high_disk_io[1].append(time)

    low_time_max = max(low_disk_io[1])
    high_time_max = max(high_disk_io[1])
    time_max = max(low_time_max, high_time_max)

    fig = plt.figure(layout="tight")
    ax1 = fig.add_subplot(2, 1, 2)
    setup_fig(ax1, low_disk_io, time_max)
    ax2 = fig.add_subplot(2, 1, 1)
    setup_fig(ax2, high_disk_io, time_max)
    
    plt.savefig("{}/{}.png".format(dirname, filename_without_ext))

if __name__ == "__main__": 
    calc_disk_io_cumulative_sum()
    gen_disk_io_scatter_plot()
