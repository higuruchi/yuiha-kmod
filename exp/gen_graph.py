import sys
import pandas as pd
from matplotlib import pyplot as plt
import matplotlib.ticker as ptick
import numpy as np

args = sys.argv
yuiha_exp_data_path = args[1]
nilfs_exp_data_path = args[2]

yuiha_df = pd.read_csv(yuiha_exp_data_path)
nilfs_df = pd.read_csv(nilfs_exp_data_path)

yuiha_seq_df = yuiha_df.query('mode == "seq"')
nilfs_seq_df = nilfs_df.query('mode == "seq"')

# yuiha_append_df = yuiha_df.query('mode == "append"')
# nilfs_append_df = nilfs_df.query('mode == "append"')

fig_seq = plt.figure(figsize=(20, 4))
# fig_append = plt.figure(figsize=(20, 4))
width = 0.2

# NILFS
nilfs_seq_ax = fig_seq.add_subplot(1, 5, 1)
nilfs_seq_ax.bar(nilfs_seq_df["size"], nilfs_seq_df["diff_img_size"], width)
nilfs_seq_ax.set_xlabel("Sequential write Size", loc="center")
nilfs_seq_ax.set_ylabel("Disk usage of nilfs(KB)")
nilfs_seq_ax.set_yscale("log")

# nilfs_append_ax = fig_append.add_subplot(1, 5, 1)
# nilfs_append_ax.bar(nilfs_append_df["size"], nilfs_seq_df["diff_img_size"], width)
# nilfs_append_ax.set_xlabel("Append write Size", loc="center")
# nilfs_append_ax.set_ylabel("Disk usage of nilfs(KB)")
# nilfs_append_ax.set_yscale("log")

# YuihaFS
yuiha_seq_ax = fig_seq.add_subplot(1, 5, (2, 3))
yuiha_seq_ax.yaxis.set_major_formatter(ptick.ScalarFormatter(useMathText=True))
yuiha_seq_ax.ticklabel_format(style="sci",  axis="y",scilimits=(4,4))
yuiha_seq_60k_df = yuiha_seq_df.query('size == "60k"')["diff_img_size"]
yuiha_seq_250k_df = yuiha_seq_df.query('size == "250k"')["diff_img_size"]
yuiha_seq_1000k_df = yuiha_seq_df.query('size == "1000k"')["diff_img_size"]
yuiha_seq_4000k_df = yuiha_seq_df.query('size == "4000k"')["diff_img_size"]

x = np.array([1, 2, 3, 4])
labels = ["100%", "50%", "20%", "10%"]
left = np.arange(len(yuiha_seq_4000k_df))
width = 0.2

yuiha_seq_ax.bar(x=left,
        height=yuiha_seq_60k_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="60KB")
yuiha_seq_ax.bar(x=left+width,
        height=yuiha_seq_250k_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="250KB")
yuiha_seq_ax.bar(x=left+width*2,
        height=yuiha_seq_1000k_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="1MB")
yuiha_seq_ax.bar(x=left+width*3,
        height=yuiha_seq_4000k_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="4MB")

yuiha_seq_ax.set_xlabel("The version creation ratio between file close and next file open")
yuiha_seq_ax.set_ylabel("Disk usage of YuihaFS(KB)")
yuiha_seq_ax.set_xticks(left + width + 0.1)
yuiha_seq_ax.set_xticklabels(labels=labels)
yuiha_seq_ax.set_yscale("log")
yuiha_seq_ax.legend()

# yuiha_append_ax = fig_append.add_subplot(1, 5, (7, 8))
# yuiha_append_ax.yaxis.set_major_formatter(ptick.ScalarFormatter(useMathText=True))
# yuiha_append_ax.ticklabel_format(style="sci",  axis="y",scilimits=(4,4))
# yuiha_append_200k_df = yuiha_append_df.query('size == "200k"')["diff_img_size"]
# yuiha_append_400k_df = yuiha_append_df.query('size == "400k"')["diff_img_size"]
# yuiha_append_800k_df = yuiha_append_df.query('size == "800k"')["diff_img_size"]
# yuiha_append_1600k_df = yuiha_append_df.query('size == "1600k"')["diff_img_size"]
# 
# x = np.array([1, 2, 3, 4])
# yuiha_append_labels = ["100%", "50%", "20%", "10%"]
# left = np.arange(len(yuiha_append_1600k_df))
# width = 0.2
# 
# yuiha_append_ax.bar(x=left,
#         height=yuiha_append_200k_df,
#         width=width,
#         align='center',
#         edgecolor="black",
#         linewidth=1,
#         label="200KB")
# yuiha_append_ax.bar(x=left+width,
#         height=yuiha_append_400k_df,
#         width=width,
#         align='center',
#         edgecolor="black",
#         linewidth=1,
#         label="400KB")
# yuiha_append_ax.bar(x=left+width*2,
#         height=yuiha_append_800k_df,
#         width=width,
#         align='center',
#         edgecolor="black",
#         linewidth=1,
#         label="800KB")
# yuiha_append_ax.bar(x=left+width*3,
#         height=yuiha_append_1600k_df,
#         width=width,
#         align='center',
#         edgecolor="black",
#         linewidth=1,
#         label="1.6MB")
# 
# yuiha_append_ax.set_xlabel("The version creation ratio between file close and next file open")
# yuiha_append_ax.set_ylabel("Disk usage of YuihaFS(KB)")
# yuiha_append_ax.set_xticks(left + width + 0.1)
# yuiha_append_ax.set_xticklabels(labels=yuiha_append_labels)
# yuiha_append_ax.set_yscale("log")
# yuiha_append_ax.legend()

# ratio of yuihafs to nilfs
yuiha_ratio_ax = fig_seq.add_subplot(1, 5, (4, 5))
nilfs_seq_60k_diff_size = nilfs_seq_df.query('size == "60k"')["diff_img_size"][4]
nilfs_seq_250k_diff_size = nilfs_seq_df.query('size == "250k"')["diff_img_size"][5]
nilfs_seq_1000k_diff_size = nilfs_seq_df.query('size == "1000k"')["diff_img_size"][6]
nilfs_seq_4000k_diff_size = nilfs_seq_df.query('size == "4000k"')["diff_img_size"][7]

yuiha_seq_60k_ratio_df = [i/nilfs_seq_60k_diff_size for i in yuiha_seq_60k_df]
yuiha_seq_250k_ratio_df = [i/nilfs_seq_250k_diff_size for i in yuiha_seq_250k_df]
yuiha_seq_1000k_ratio_df = [i/nilfs_seq_1000k_diff_size for i in yuiha_seq_1000k_df]
yuiha_seq_4000k_ratio_df = [i/nilfs_seq_4000k_diff_size for i in yuiha_seq_4000k_df]

x = np.array([1, 2, 3, 4])
labels = ["100%", "50%", "20%", "10%"]
left = np.arange(len(yuiha_seq_4000k_df))
width = 0.2

yuiha_ratio_ax.bar(x=left,
        height=yuiha_seq_60k_ratio_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="60KB")
yuiha_ratio_ax.bar(x=left+width,
        height=yuiha_seq_250k_ratio_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="250KB")
yuiha_ratio_ax.bar(x=left+width*2,
        height=yuiha_seq_1000k_ratio_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="1MB")
yuiha_ratio_ax.bar(x=left+width*3,
        height=yuiha_seq_4000k_ratio_df,
        width=width,
        align='center',
        edgecolor="black",
        linewidth=1,
        label="4MB")
yuiha_ratio_ax.set_xlabel("The version creation ratio between file close and next file open")
yuiha_ratio_ax.set_ylabel("Disk usage ratio of YuihaFS to nilfs(KB)")
yuiha_ratio_ax.set_xticks(left + width + 0.1)
yuiha_ratio_ax.set_xticklabels(labels=labels)
yuiha_ratio_ax.legend()


plt.tight_layout()
plt.savefig("hoge.png", format="png")
