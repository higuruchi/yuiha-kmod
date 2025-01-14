#!/bin/bash -x

TARGET_DIR="./exp/exp_data"

if [ ! -d "$TARGET_DIR" ]; then
	exit 1
fi

before_day=${1:-3}
limit_date=$(date --date="$before_day day ago" +"%Y-%m-%d")
unix_limit_date=$(date -d "$limit_date" +%s)

branch_name=$(git rev-parse --abbrev-ref HEAD)

for dir in "$TARGET_DIR"/*; do
	if [ -d "$dir" ]; then
		dirname=$(basename "$dir")
		exp_time=$(echo "$dirname" | sed 's/_.*//')
		unix_exp_time=$(date -d "$exp_time" +%s)

		if [ "$unix_exp_time" -le "$unix_limit_date" ]; then
			echo $exp_time
			tar -czf "${TARGET_DIR}/${dirname}.tar.gz" "${TARGET_DIR}/$dirname"
			git add "${TARGET_DIR}/${dirname}.tar.gz"
			git commit -m "${dirname}"
			git push origin ${branch_name}
			rm -rf "${TARGET_DIR}/${dirname}"
		fi
	fi
done
