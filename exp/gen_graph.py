import sys
import pandas as pd
from matplotlib import pyplot as plt
import matplotlib.ticker as ptick
import numpy as np

args = sys.argv
yuiha_exp_data_path = args[1]
nilfs_exp_data_path = args[2]
colors = ["#FF4B00", "#005AFF", "#03AF7A", "#4DC4FF"]
width = 0.2

yuiha_df = pd.read_csv(yuiha_exp_data_path)
nilfs_df = pd.read_csv(nilfs_exp_data_path)

fig_seq = plt.figure(figsize=(20, 4))

# Sequential
yuiha_seq_df = yuiha_df.query('mode == "seq"')
nilfs_seq_df = nilfs_df.query('mode == "seq"')

yuiha_seq_ax = fig_seq.add_subplot(1, 5, (1, 2))
yuiha_seq_ax.set_title("(a) The differential disk size of sequential write")
yuiha_seq_ax.set_xlabel("The version creation ratio between file close and next file open")
yuiha_seq_ax.set_ylabel("Disk usage(KB)")
yuiha_seq_ax.yaxis.set_major_formatter(ptick.ScalarFormatter(useMathText=True))
yuiha_seq_ax.ticklabel_format(style="sci",  axis="y",scilimits=(4,4))

seq_file_size = ["60k", "250k", "1000k", "4000k"]
seq_file_size_label = ["60KB", "250KB", "1MB", "4MB"]
for i, (s, l, c, n) in enumerate(zip(seq_file_size, seq_file_size_label, colors, nilfs_seq_df["diff_img_size"])):
    yuiha_seq_diff_img_size_df = yuiha_seq_df.query('size == "{}"'.format(s))["diff_img_size"]
    left = np.arange(len(yuiha_seq_diff_img_size_df))
    yuiha_seq_ax.bar(x=left + width * i,
            height=yuiha_seq_diff_img_size_df,
            width=width,
            align='center',
            color=c,
            edgecolor="black",
            linewidth=1,
            label="YFS({})".format(l))
    yuiha_seq_ax.hlines(y=n, xmin=-0.1, xmax=3.7, colors=c, label="nilfs({})".format(l))

yuiha_seq_ax.set_xticks(left + width + 0.1)
ratio_labels = ["100%", "50%", "20%", "10%"]
yuiha_seq_ax.set_xticklabels(labels=ratio_labels)
yuiha_seq_ax.set_yscale("log")
yuiha_seq_ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', borderaxespad=0)

# Append
yuiha_append_df = yuiha_df.query('mode == "append"')
nilfs_append_df = nilfs_df.query('mode == "append"')

yuiha_append_ax = fig_seq.add_subplot(1, 5, (3, 4))
yuiha_append_ax.set_title("(b) The differential disk size of append write")
yuiha_append_ax.set_xlabel("The version creation ratio between file close and next file open")
yuiha_append_ax.set_ylabel("Disk usage(KB)")
yuiha_append_ax.yaxis.set_major_formatter(ptick.ScalarFormatter(useMathText=True))
yuiha_append_ax.ticklabel_format(style="sci",  axis="y",scilimits=(4,4))

append_write_size = ["200KB", "400KB", "800KB", "1600KB"]
append_write_size_label = ["200KB", "400KB", "800KB", "1.6MB"]
for i, (a, l, c, n) in enumerate(zip(append_write_size, append_write_size_label, colors, nilfs_append_df["diff_img_size"])):
    yuiha_append_diff_img_size_df = yuiha_append_df.query('size == "{}"'.format(a))["diff_img_size"]
    left = np.arange(len(yuiha_append_diff_img_size_df))
    yuiha_append_ax.bar(x=left + width * i,
            height=yuiha_append_diff_img_size_df,
            width=width,
            align='center',
            color=c,
            edgecolor="black",
            linewidth=1,
            label="YFS({})".format(l))
    yuiha_append_ax.hlines(y=n, xmin=-0.1, xmax=3.7, colors=c, label="nilfs({})".format(l))

yuiha_append_ax.set_xticks(left + width + 0.1)
ratio_labels = ["100%", "50%", "20%", "10%"]
yuiha_append_ax.set_xticklabels(labels=ratio_labels)
yuiha_append_ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', borderaxespad=0)

plt.tight_layout()
plt.savefig("hoge.png", format="png")
