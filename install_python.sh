#!/bin/bash

# Function to install a specific Python version with optimizations
install_python() {
    VERSION=$1
    PYTHON_BIN="/usr/local/bin/python${VERSION%.*}"

    # Check if the version is already installed
    echo "Installing Python $VERSION with optimizations..."

    # Update package list
    sudo apt update

    # Install build dependencies
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
        libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget \
        curl xz-utils tk-dev liblzma-dev uuid-dev libbz2-dev

    # Download and compile Python
    cd /tmp
    curl -O https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz
    tar -xvzf Python-$VERSION.tgz
    cd Python-$VERSION

    ./configure --enable-optimizations --with-lto
    make -j "$(nproc)" profile-opt  # Uses PGO
    sudo make altinstall

    # Clean up
    cd ..
    rm -rf Python-$VERSION Python-$VERSION.tgz

    # Ensure pip is installed
    $PYTHON_BIN -m ensurepip

    # Verify installation
    $PYTHON_BIN --version

    # Install pyperformance if not already installed
    if ! $PYTHON_BIN -m pip show pyperformance &>/dev/null; then
        echo "Installing pyperformance for $PYTHON_BIN..."
        $PYTHON_BIN -m pip install --upgrade pip
        $PYTHON_BIN -m pip install pyperformance
    else
        echo "pyperformance is already installed for $PYTHON_BIN."
    fi
}

run_benchmarks() {
    PYTHON_VERSION=$1
    PYTHON_PATH=$2 
    $PYTHON_VERSION -m pyperformance run --benchmarks=2to3,chameleon,tornado_http \
        --python=$PYTHON_PATH -o ${PYTHON_VERSION}.json
}

# Install Python versions with optimizations
install_python "3.9.22"
install_python "3.10.17"
install_python "3.11.12"
install_python "3.12.10"
install_python "3.13.3"

echo "Installation complete!"
