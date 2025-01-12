#!/usr/bin/env python3

import sys
import pandas as pd
from matplotlib import pyplot as plt
import matplotlib.ticker as ptick
import numpy as np
from pathlib import Path

args = sys.argv
yuiha_exp_data_path = args[1]
ext3_exp_data_path = args[2]
colors = ["#FF4B00", "#005AFF", "#03AF7A", "#4DC4FF", "#F6AA00"]
width = 0.15

yuiha_df = pd.read_csv(yuiha_exp_data_path)
ext3_df = pd.read_csv(ext3_exp_data_path)

fig_seq = plt.figure(figsize=(7, 10))

# Sequential
yuiha_seq_df = yuiha_df.query('mode == "seq"')
ext3_seq_df = ext3_df.query('mode == "seq"')

ss_span = ["ext3", "1", "2", "4", "200"]
ss_span_label =["ext3", "100%", "50%", "25%", "0%"]

yuiha_seq_ax = fig_seq.add_subplot(6, 1, (1, 2))
yuiha_seq_ax.set_title("(a) Sequential write", y=-0.27)
yuiha_seq_ax.set_xlabel("Sequential write size")
yuiha_seq_ax.set_ylabel("Write throughput(B)")
yuiha_seq_ax.yaxis.set_major_formatter(ptick.ScalarFormatter(useMathText=True))
yuiha_seq_ax.ticklabel_format(style="sci",  axis="y",scilimits=(4,5))

for i, (s, l, c) in enumerate(zip(ss_span, ss_span_label, colors)):
    yuiha_seq_diff_img_size_df = []
    label=""
    if s == "ext3":
        yuiha_seq_diff_img_size_df = ext3_seq_df["mean_write_bw"]
        label="ext3"
    else:
        yuiha_seq_diff_img_size_df = \
            yuiha_seq_df.query('ss_span == {}'.format(s))["mean_write_bw"]
        label="YFS({})".format(l)

    left = np.arange(len(yuiha_seq_diff_img_size_df))
    yuiha_seq_ax.bar(x=left + width * i,
            height=yuiha_seq_diff_img_size_df,
            width=width,
            align='center',
            color=c,
            edgecolor="black",
            linewidth=1,
            label=label)

yuiha_seq_ax.set_xticks(left + width + 0.1)
seq_file_size_label = ["8MB", "16MB", "32MB", "64MB"]
yuiha_seq_ax.set_xticklabels(labels=seq_file_size_label)
yuiha_seq_ax.legend(loc="upper left", bbox_to_anchor=(1, 1))

plt.tight_layout()

fig_file_name="write_throughput-{}-{}.png".format(
        Path(yuiha_exp_data_path).parent.name,
        Path(ext3_exp_data_path).parent.name)
plt.savefig(fig_file_name, format="png")
print("Generate {}".format(fig_file_name))
