#!/bin/bash

sudo apt update && sudo apt install adb default-jdk -y

git clone https://github.com/skylot/jadx.git
cd jadx
./gradlew dist

ln -s ./build/jadx/bin/* ~/.local/bin/
