#!/usr/bin/env bash
# Simple environment setup script for RustDesk development on Debian/Ubuntu
set -euo pipefail

# Install required packages
sudo apt update
sudo apt install -y zip g++ gcc git curl wget nasm yasm libgtk-3-dev clang \
  libxcb-randr0-dev libxdo-dev libxfixes-dev libxcb-shape0-dev libxcb-xfixes0-dev \
  libasound2-dev libpulse-dev cmake make libclang-dev ninja-build \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libpam0g-dev

# Install Rust toolchain if not present
if ! command -v cargo >/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Clone submodules
git submodule update --init --recursive

# Install vcpkg
if [ ! -d "$HOME/vcpkg" ]; then
    git clone https://github.com/microsoft/vcpkg "$HOME/vcpkg"
    (cd "$HOME/vcpkg" && git checkout 2023.04.15 && ./bootstrap-vcpkg.sh)
fi
export VCPKG_ROOT="$HOME/vcpkg"
# The repository contains a vcpkg manifest (vcpkg.json) so
# packages are defined there. Running `vcpkg install` without
# additional package arguments ensures the dependencies
# specified in the manifest are installed correctly.
"$VCPKG_ROOT"/vcpkg install

# Download sciter library
mkdir -p target/debug
if [ ! -f target/debug/libsciter-gtk.so ]; then
    wget https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.lnx/x64/libsciter-gtk.so \
         -O target/debug/libsciter-gtk.so
fi

# Build project
VCPKG_ROOT="$VCPKG_ROOT" cargo build "$@"
