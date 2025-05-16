#!/bin/bash
set -euo pipefail

# Function to install a specific Python version with optimizations
install_python() {
    VERSION=$1
    PYTHON_BIN="/usr/local/bin/python${VERSION%.*}"

    # Check if the version is already installed
    if [ -x "$PYTHON_BIN" ] && [[ "$($PYTHON_BIN --version 2>&1)" == *"$VERSION"* ]]; then
        echo "Python $VERSION is already installed."
        return
    fi

    echo "Installing Python $VERSION with optimizations..."

    # Ensure we have some swap space so the linker doesn't get killed
    SWAPFILE=/swapfile
    if ! swapon --show | grep -q "$SWAPFILE"; then
        echo ">>> Creating 1G swap file at $SWAPFILE"
        fallocate -l 1G "$SWAPFILE"
        chmod 600 "$SWAPFILE"
        mkswap "$SWAPFILE"
        swapon "$SWAPFILE"
    fi

    # Install build dependencies (for Alpine)
    apk update
    apk add --no-cache build-base zlib-dev ncurses-dev gdbm-dev \
        libnss3-dev openssl-dev readline-dev libffi-dev sqlite-dev \
        wget curl xz tk-dev liblzma-dev uuid-dev bzip2-dev

    # Download and compile Python
    cd /tmp
    curl -O https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz
    tar -xzf Python-$VERSION.tgz
    cd Python-$VERSION

    # Configure the build: enable optimizations, but disable LTO
    ./configure \
        --prefix=/usr/local \
        --enable-optimizations \
        --with-ensurepip \
        --without-lto

    # Build Python with PGO, but limit to 1 job to avoid OOM
    MAKEFLAGS="-j1" make profile-opt

    # Install Python
    make altinstall

    # Clean up build artifacts and swap
    cd /tmp
    rm -rf Python-$VERSION Python-$VERSION.tgz

    echo ">>> Removing swap file"
    swapoff "$SWAPFILE"
    rm -f "$SWAPFILE"

    # Ensure pip is installed & verify
    $PYTHON_BIN -m ensurepip --upgrade
    $PYTHON_BIN --version
}

# Install your desired version
install_python "3.13.3"

echo "Installation complete!"
