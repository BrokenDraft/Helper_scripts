#!/bin/bash

# Depends on the repo binary

mkdir -p ~/aosp && cd ~/aosp
repo init -u https://android.googlesource.com/platform/manifest/ -b main
repo sync -c -j8
