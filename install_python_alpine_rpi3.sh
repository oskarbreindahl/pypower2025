#!/bin/bash
set -euo pipefail

install_python() {
    VERSION=$1
    PYTHON_BIN="/usr/local/bin/python${VERSION%.*}"

    if [ -x "$PYTHON_BIN" ] && [[ "$($PYTHON_BIN --version 2>&1)" == *"$VERSION"* ]]; then
        echo "Python $VERSION is already installed."
        return
    fi

    echo "Installing Python $VERSION with optimizations..."

    SWAPFILE=/swapfile
    # Only make swap if it's not already active
    if ! grep -q "^$SWAPFILE" /proc/swaps; then
        echo ">>> Creating 1G swap file at $SWAPFILE"
        fallocate -l 1G "$SWAPFILE" || dd if=/dev/zero of="$SWAPFILE" bs=1M count=1024
        chmod 600 "$SWAPFILE"
        mkswap "$SWAPFILE"
        swapon "$SWAPFILE"
    fi

    apk update
    apk add --no-cache build-base zlib-dev ncurses-dev gdbm-dev \
        libnss3-dev openssl-dev readline-dev libffi-dev sqlite-dev \
        wget curl xz tk-dev liblzma-dev uuid-dev bzip2-dev

    cd /tmp
    curl -O https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz
    tar -xzf Python-$VERSION.tgz
    cd Python-$VERSION

    ./configure \
        --prefix=/usr/local \
        --enable-optimizations \
        --with-ensurepip \
        --without-lto

    MAKEFLAGS="-j1" make profile-opt
    make altinstall

    cd /tmp
    rm -rf Python-$VERSION Python-$VERSION.tgz

    echo ">>> Tearing down swap"
    swapoff "$SWAPFILE"
    rm -f "$SWAPFILE"

    $PYTHON_BIN -m ensurepip --upgrade
    $PYTHON_BIN --version
}

install_python "3.13.3"
echo "Installation complete!"
