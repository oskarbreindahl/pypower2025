#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\n>>> $1\n"; }

install_python() {
    VERSION=$1
    PYTHON_BIN="/usr/local/bin/python${VERSION%.*}"

    # already installed?
    if [ -x "$PYTHON_BIN" ] && [[ "$($PYTHON_BIN --version 2>&1)" == *"$VERSION"* ]]; then
        log "Python $VERSION is already installed."
        return
    fi

    log "Installing Python $VERSION with optimizations..."

    # 1) create swap if needed
    SWAPFILE=/swapfile
    if ! grep -q "^$SWAPFILE" /proc/swaps; then
        log "Creating 1G swap at $SWAPFILE"
        if ! fallocate -l 1G "$SWAPFILE" 2>/dev/null; then
            log "fallocate missing – falling back to dd"
            dd if=/dev/zero of="$SWAPFILE" bs=1M count=1024 status=none
        fi
        chmod 600 "$SWAPFILE"
        mkswap "$SWAPFILE"
        swapon "$SWAPFILE"
    else
        log "Swap file already active, skipping creation"
    fi

    # 2) update + install deps
    log "Updating apk index"
    apk update || { echo "apk update failed"; exit 1; }

    # 3) download & extract
    cd /tmp
    log "Downloading Python-$VERSION"
    curl -fsSLO https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz \
        || { echo "curl download failed"; exit 1; }

    log "Extracting archive"
    tar -xzf Python-$VERSION.tgz

    # 4) configure & build
    cd Python-$VERSION
    log "Configuring (no LTO)"
    ./configure \
        --prefix=/usr/local \
        --enable-optimizations \
        --with-ensurepip \
        --without-lto \
    || { echo "configure failed"; exit 1; }

    log "Building with PGO (MAKEFLAGS=\"-j1\")"
    MAKEFLAGS="-j1" make profile-opt \
        || { echo "make profile-opt failed"; exit 1; }

    log "Installing"
    make altinstall \
        || { echo "make altinstall failed"; exit 1; }

    # 5) cleanup
    cd /tmp
    rm -rf Python-$VERSION Python-$VERSION.tgz

    log "Tearing down swap"
    swapoff "$SWAPFILE" || echo "swapoff warnings"
    rm -f "$SWAPFILE"

    # 6) final checks
    log "Upgrading pip and verifying"
    /usr/local/bin/python${VERSION%.*} -m ensurepip --upgrade
    /usr/local/bin/python${VERSION%.*} --version
}

install_python "3.13.3"
log "All done!"
