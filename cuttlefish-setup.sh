#!/bin/bash
set -euo pipefail

WORKDIR="$HOME/cuttlefish"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

CF_REPO_LINE="deb https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts android-cuttlefish main"
CF_LIST=/etc/apt/sources.list.d/artifact-registry.list

BUILD_ID="16644040"
TARGET="aosp_cf_x86_64_only_phone-userdebug"
BASE_URL="https://ci.android.com/builds/submitted/$BUILD_ID/$TARGET/latest"

IMG_ZIP="aosp_cf_x86_64_only_phone-img-$BUILD_ID.zip"
HOST_PKG="cvd-host_package.tar.gz"

# ---------------------------------------------------------------------------
# Download helper: ci.android.com serves an HTML viewer page, not the file.
# Extract the signed GCS URL from JSVariables['artifactUrl'] and fetch that.
# ---------------------------------------------------------------------------
download_ci_artifact() {
    local page_url="$1" out="$2" real_url

    real_url=$(curl -fsSL "$page_url" | python3 -c '
import sys, re, json
html = sys.stdin.read()
m = re.search(r"\"artifactUrl\":(\".*?\")", html)
if not m:
    sys.exit(1)
print(json.loads(m.group(1)))
') || { echo "Could not extract artifactUrl from $page_url" >&2; return 1; }

    echo "Downloading $out ..."
    curl -fL -C - -o "$out" "$real_url"
}

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------
sudo apt install -y python3 python3-pip git unzip \
    libvirt-clients libvirt-daemon-system qemu-kvm bridge-utils

# ---------------------------------------------------------------------------
# Artifacts
# ---------------------------------------------------------------------------
rm -f "$IMG_ZIP" "$HOST_PKG"   # clear any corrupt leftovers from earlier runs

download_ci_artifact "$BASE_URL/$IMG_ZIP" "$IMG_ZIP"
download_ci_artifact "$BASE_URL/$HOST_PKG" "$HOST_PKG"

# Fail fast on truncated/corrupt downloads before extracting
unzip -t "$IMG_ZIP" > /dev/null
tar -tzf "$HOST_PKG" > /dev/null

unzip "$IMG_ZIP"
tar -xzf "$HOST_PKG"

# Cuttlefish apt repo (idempotent, no duplicate entries on rerun)
mkdir -p ~/.local/tmp && cd ~/.local/tmp
sudo apt install -y devscripts equivs config-package-dev debhelper-compat golang curl
git clone https://github.com/google/android-cuttlefish
cd android-cuttlefish
tools/buildutils/build_packages.sh
sudo dpkg -i ./cuttlefish-base_*_*64.deb || sudo apt-get install -f
sudo dpkg -i ./cuttlefish-user_*_*64.deb || sudo apt-get install -f
sudo usermod -aG kvm,cvdnetwork,render $USER
sudo reboot

echo "Done. To launch: HOME=$(pwd) bin/launch_cvd --num_instances=1"
