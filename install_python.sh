#!/bin/bash

# Function to install a specific Python version
install_python() {
    VERSION=$1
    PYTHON_BIN="python${VERSION%.*}"

    # Check if the version is already installed
    if command -v $PYTHON_BIN &>/dev/null; then
        echo "$PYTHON_BIN is already installed."
    else
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
        $VERSION -m ensurepip

        # Verify the installation
        $PYTHON_BIN --version
    fi

    # Install pyperformance if not already installed for the specific Python version
    if ! $PYTHON_BIN -m pip show pyperformance &>/dev/null; then
        echo "Installing pyperformance for $PYTHON_BIN..."
        $PYTHON_BIN -m pip install pyperformance
    else
        echo "pyperformance is already installed for $PYTHON_BIN."
    fi
}

run_benchmarks() {
    PYTHON_VERSION=$1
    PYTHON_PATH=$2 
    $PYTHON_VERSION -m pyperformance run --benchmarks=2to3,chameleon,tornado_http --python=$PYTHON_PATH -o $PYTHON_VERSION.json
}

# Install Python 3.9
install_python "3.9.22"

# Install Python 3.10
install_python "3.10.17"

# Install Python 3.11
install_python "3.11.12"

# Install Python 3.12
install_python "3.12.10"

# Install Python 3.13
install_python "3.13.3"

echo "Installation complete!"