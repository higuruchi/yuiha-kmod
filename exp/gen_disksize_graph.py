import sys
import pandas as pd
from matplotlib import pyplot as plt
import matplotlib.ticker as ptick
import numpy as np

args = sys.argv
yuiha_exp_data_path = args[1]
nilfs_exp_data_path = args[2]
colors = ["#FF4B00", "#005AFF", "#03AF7A", "#4DC4FF", "#F6AA00"]
width = 0.15

yuiha_df = pd.read_csv(yuiha_exp_data_path)
nilfs_df = pd.read_csv(nilfs_exp_data_path)

fig_seq = plt.figure(figsize=(5, 10))

# Sequential
yuiha_seq_df = yuiha_df.query('mode == "seq"')
nilfs_seq_df = nilfs_df.query('mode == "seq"')

ss_span = ["nilfs", "1", "2", "4"]
ss_span_label = ["nilfs", "100%", "50%", "25%"]

yuiha_seq_ax = fig_seq.add_subplot(6, 1, (1, 2))
yuiha_seq_ax.set_title("(a) The differential disk size of sequential write", y=-0.27)
yuiha_seq_ax.set_xlabel("Sequential write size")
yuiha_seq_ax.set_ylabel("Disk usage(KB)")
yuiha_seq_ax.yaxis.set_major_formatter(ptick.ScalarFormatter(useMathText=True))
yuiha_seq_ax.ticklabel_format(style="sci",  axis="y",scilimits=(4,4))

for i, (s, l, c) in enumerate(zip(ss_span, ss_span_label, colors)):
    yuiha_seq_diff_img_size_df = []
    label=""
    if s == "nilfs":
        yuiha_seq_diff_img_size_df = nilfs_seq_df["diff_img_size"]
        label="nilfs"
    else:
        yuiha_seq_diff_img_size_df = yuiha_seq_df.query('ss_span == {}'.format(s))["diff_img_size"]
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
seq_file_size_label = ["60KB", "250KB", "1MB", "4MB"]
yuiha_seq_ax.set_xticklabels(labels=seq_file_size_label)
yuiha_seq_ax.set_yscale("log")
yuiha_seq_ax.legend(loc='upper left')

# Append
yuiha_append_df = yuiha_df.query('mode == "append"')
nilfs_append_df = nilfs_df.query('mode == "append"')

yuiha_append_ax = fig_seq.add_subplot(6, 1, (3, 4))
yuiha_append_ax.set_title("(b) The differential disk size of append write", y=-0.27)
yuiha_append_ax.set_xlabel("Append size")
yuiha_append_ax.set_ylabel("Disk usage(KB)")
yuiha_append_ax.yaxis.set_major_formatter(ptick.ScalarFormatter(useMathText=True))
yuiha_append_ax.ticklabel_format(style="sci",  axis="y",scilimits=(4,4))

for i, (a, l, c) in enumerate(zip(ss_span, ss_span_label, colors)):
    yuiha_append_diff_img_size_df = []
    label = ""
    if a == "nilfs":
        yuiha_append_diff_img_size_df = nilfs_append_df["diff_img_size"]
        label = "nilfs"
    else:
        yuiha_append_diff_img_size_df = yuiha_append_df.query('ss_span == {}'.format(a))["diff_img_size"]
        label = "YFS({})".format(l)
    left = np.arange(len(yuiha_append_diff_img_size_df))
    yuiha_append_ax.bar(x=left + width * i,
            height=yuiha_append_diff_img_size_df,
            width=width,
            align='center',
            color=c,
            edgecolor="black",
            linewidth=1,
            label=label)

yuiha_append_ax.set_xticks(left + width + 0.1)
append_write_size_label = ["200KB", "400KB", "800KB", "1.6MB"]
yuiha_append_ax.set_xticklabels(labels=append_write_size_label)
yuiha_append_ax.legend(loc='upper left')

plt.tight_layout()
plt.savefig("disksize.png", format="png")
