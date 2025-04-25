#!/bin/bash

# Install pyenv if not already installed
if ! command -v pyenv &>/dev/null; then
    echo "Installing pyenv..."

    # Install pyenv dependencies
    sudo apt update
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev git

    # Clone pyenv
    curl https://pyenv.run | bash

    # Add pyenv to bash profile
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"

    # Persist pyenv in shell profile
    if ! grep -q 'pyenv init' ~/.bashrc; then
        echo -e '\n# Pyenv configuration' >> ~/.bashrc
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
    fi
else
    echo "pyenv is already installed."
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Function to install Python and pyperformance
install_python() {
    VERSION=$1

    if pyenv versions --bare | grep -q "^${VERSION}$"; then
        echo "Python $VERSION already installed via pyenv."
    else
        echo "Installing Python $VERSION via pyenv..."
        pyenv install $VERSION
    fi

    pyenv shell $VERSION

    if ! pip show pyperformance &>/dev/null; then
        echo "Installing pyperformance for Python $VERSION..."
        pip install --upgrade pip
        pip install pyperformance
    else
        echo "pyperformance already installed for Python $VERSION."
    fi
}

run_benchmarks() {
    PYTHON_VERSION=$1
    PYTHON_PATH=$(pyenv prefix $PYTHON_VERSION)/bin/python

    echo "Running pyperformance for Python $PYTHON_VERSION..."
    $PYTHON_PATH -m pyperformance run \
        --benchmarks=2to3,chameleon,tornado_http \
        --python=$PYTHON_PATH -o ${PYTHON_VERSION}.json
}

# Install specific Python versions and pyperformance
install_python "3.9.15"
install_python "3.10.0"
install_python "3.11.0"
install_python "3.12.0"
install_python "3.13.0"

echo "Installation complete!"
