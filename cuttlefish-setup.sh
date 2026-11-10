#!/bin/bash
# cuttlefish-setup.sh — idempotent HOST setup for Cuttlefish
#
# This script installs ONLY host-side plumbing: virtualization packages
# and cuttlefish-base/cuttlefish-user (drivers, udev rules, virtual
# networking). Nothing Android is downloaded here. The system image, the
# launcher and the fuzzers all come from the local AOSP build in ~/aosp.
# 
#
# Safe to re-run at any time: every step checks before it acts.
#
# Daily example workflow (after the one-time full `m` in ~/aosp):
#
#   terminal 2 (device, occupies the terminal with logs):
#     cd ~/cuttlefish
#     HOME=$PWD bin/launch_cvd \
#       --system_image_dir=/media/user/Sabrent500/aosp/out/target/product/vsoc_x86_64_only \
#       --num_instances=1
#
#   terminal 1 (build):
#     cd ~/aosp
#     source build/envsetup.sh
#     lunch aosp_cf_x86_64_only_phone-trunk_staging-userdebug
#     m example_fuzzer            # rebuild whatever fuzzer you're working on
#     adb root && adb sync data
#     adb shell /data/fuzz/x86_64/example_fuzzer/example_fuzzer

set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Base packages (apt is idempotent by itself)
# ---------------------------------------------------------------------------
sudo apt update
sudo apt install -y git libvirt-clients libvirt-daemon-system \
    qemu-kvm bridge-utils

# ---------------------------------------------------------------------------
# 2. Cuttlefish host packages.
#    These are host plumbing only and are independent of the Android build,
#    so they never need to match the image version. Skipped when installed.
#    To force a rebuild/reinstall: sudo apt remove cuttlefish-base cuttlefish-user
# ---------------------------------------------------------------------------
if dpkg -s cuttlefish-base >/dev/null 2>&1 && dpkg -s cuttlefish-user >/dev/null 2>&1; then
    echo "cuttlefish host packages already installed, skipping."
else
    sudo apt install -y devscripts equivs config-package-dev debhelper-compat golang
    CF_SRC="$HOME/Repo/android-cuttlefish"
    if [ ! -d "$CF_SRC" ]; then
        git clone https://github.com/google/android-cuttlefish "$CF_SRC"
    fi
    ( cd "$CF_SRC" && tools/buildutils/build_packages.sh )
    sudo dpkg -i "$CF_SRC"/cuttlefish-base_*_*64.deb \
                 "$CF_SRC"/cuttlefish-user_*_*64.deb \
        || sudo apt-get install -f
fi

# ---------------------------------------------------------------------------
# 3. Group membership. usermod is a no-op if already a member; reboot only
#    when the current session does not have the groups yet.
# ---------------------------------------------------------------------------
for grp in kvm cvdnetwork render; do
    sudo usermod -aG "$grp" "$USER"
done

if ! id -nG | tr ' ' '\n' | grep -qx kvm; then
    echo "Groups changed; rebooting so they take effect."
    sudo reboot
fi

echo "Host setup complete. See the header comment for the daily workflow."
