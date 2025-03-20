#!/bin/bash

# Function to install a specific Python version
install_python() {
    VERSION=$1
    PYTHON_BIN="python${VERSION%.*}"

    # Check if the version is already installed
    if command -v $PYTHON_BIN &>/dev/null; then
        echo "$PYTHON_BIN is already installed."
        return
    fi

    echo "Installing Python $VERSION..."

    # Update package list
    sudo apt update

    # Install dependencies
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl

    # Download and install the specified Python version
    cd /tmp
    curl -O https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz
    tar -xvzf Python-$VERSION.tgz
    cd Python-$VERSION
    ./configure --enable-optimizations
    make -j "$(nproc)"
    sudo make altinstall

    # Clean up
    cd ..
    rm -rf Python-$VERSION
    rm Python-$VERSION.tgz

    # Verify the installation
    $PYTHON_BIN --version
}

# Function to install PyPy
install_pypy() {
    PYTHON_VERSION=$1
    PYPY_VERSION=$2
    PYPY_BIN="pypy${PYTHON_VERSION}"

    # Check if PyPy is already installed
    if command -v $PYPY_BIN &>/dev/null; then
        echo "$PYPY_BIN is already installed."
        return
    fi

    echo "Installing PyPy $PYPY_VERSION for Python $PYTHON_VERSION..."

    # PyPy URL with version numbers for Python and PyPy
    URL="https://downloads.python.org/pypy/pypy${PYTHON_VERSION}-v${PYPY_VERSION}-linux64.tar.bz2"
    FILE="pypy${PYTHON_VERSION}-v${PYPY_VERSION}-linux64.tar.bz2"
    
    # Download and install PyPy
    cd /tmp
    curl -O $URL
    tar -xvjf $FILE  # Using bzip2 decompression (tar -xvjf for .tar.bz2 files)
    sudo mv pypy${PYTHON_VERSION}-v${PYPY_VERSION}-linux64 /opt/pypy${PYTHON_VERSION}-v${PYPY_VERSION}

    # Create a symbolic link
    sudo ln -s /opt/pypy${PYTHON_VERSION}-v${PYPY_VERSION}/bin/pypy3 /usr/local/bin/pypy${PYTHON_VERSION}

    # Clean up
    rm $FILE

    # Verify the installation
    $PYPY_BIN --version
}

# Install Python 3.9
install_python "3.9.15"

# Install Python 3.12
install_python "3.12.0"

# Install Python 3.13
install_python "3.13.0"

# Install PyPy for Python 3.9 (v7.3.9 is the stable version)
install_pypy "3.9" "7.3.9"

# Install PyPy for Python 3.11 (v7.3.19 is the latest stable version)
install_pypy "3.11" "7.3.19"

echo "Installation complete!"
