#!/bin/bash

mkdir -p ~/.local/bin 
mkdir -p ~/Downloads
cd ~/Downloads

wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
mv platform-tools ~/.local/bin/

rm platform-tools-latest-linux.zip

echo -e "\n\n\t add : \`PATH=\$PATH:~/.local/bin/platform-tools\` to your env file"
