#!/bin/bash

# Function to install a specific Python version with optimizations
install_python() {
    VERSION=$1
    PYTHON_BIN="/usr/local/bin/python${VERSION%.*}"

    # Check if the version is already installed
    if [ -x "$PYTHON_BIN" ] && [[ "$($PYTHON_BIN --version 2>&1)" == *"$VERSION"* ]]; then
        echo "Python $VERSION is already installed."
    else
        echo "Installing Python $VERSION with optimizations..."

        # Ensure DNF cache is up-to-date
        sudo dnf makecache

        # Install build dependencies
        sudo dnf install -y \
            @development-tools \
            zlib-devel ncurses-devel gdbm-devel nss-devel \
            openssl-devel readline-devel libffi-devel sqlite-devel \
            wget curl xz libuuid-devel bzip2-devel tk-devel

        # Download and compile Python
        cd /tmp
        curl -O "https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz"
        tar xf "Python-$VERSION.tgz"
        cd "Python-$VERSION"

        ./configure --enable-optimizations --with-lto
        make -j"$(nproc)" profile-opt
        sudo make altinstall

        # Clean up
        cd /tmp
        rm -rf "Python-$VERSION" "Python-$VERSION.tgz"

        # Ensure pip is installed
        $PYTHON_BIN -m ensurepip

        # Verify installation
        $PYTHON_BIN --version
    fi

    # Install pyperformance if not already installed
    if ! $PYTHON_BIN -m pip show pyperformance &>/dev/null; then
        echo "Installing pyperformance for $PYTHON_BIN..."
        $PYTHON_BIN -m pip install --upgrade pip
        $PYTHON_BIN -m pip install pyperformance
    else
        echo "pyperformance is already installed for $PYTHON_BIN."
    fi
}

# Install Python versions with optimizations
install_python "3.9.22"
install_python "3.10.17"
install_python "3.11.12"
install_python "3.12.10"
install_python "3.13.3"

echo "Installation complete!"
