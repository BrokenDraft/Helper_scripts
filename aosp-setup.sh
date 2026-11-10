#!/bin/bash

# Depends on the repo binary

echo -e "---WARNING---\t This will pull the AOSP project repo's. It will take a few hours"
read -p "Are you sure? [y/N]" -n 1 -r reply
reply=${reply:-"N"}
echo
if [[ $reply =~ ^[Yy]$ ]]; then
	mkdir -p ~/aosp && cd ~/aosp
	repo init -u https://android.googlesource.com/platform/manifest/ -b main
	repo sync -c -j8
fi
