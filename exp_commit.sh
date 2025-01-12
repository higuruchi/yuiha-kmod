#!/bin/bash -x

TARGET_DIR="./exp/exp_data"

if [ ! -d "$TARGET_DIR" ]; then
	exit 1
fi

for dir in "$TARGET_DIR"/*; do
	if [ -d "$dir" ]; then
		dirname=$(basename "$dir")
		tar -czf "$TARGET_DIR/${dirname}.tar.gz" "$dirname"
		git add "$TARGET_DIR/${dirname}.tar.gz"
		git commit -m "${dirname}"
		git push origin main
		rm -rf "$TARGET_DIR/$dirname"
	fi
done
