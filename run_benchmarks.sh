#!/bin/bash

# Function to run benchmarks on a specific Python or PyPy version
run_benchmarks() {
    PYTHON_BIN=$1
    PYTHON_PATH=$2 
    $PYTHON_BIN -m pyperformance run --benchmarks=2to3,chameleon,tornado_http --python=$PYTHON_PATH -o $PYTHON_BIN.json
}

# List of installed Python and PyPy versions (full implementation names)
PYTHON_VERSIONS=("python3.9" "python3.12" "python3.13" "pypy3.9" "pypy3.11")  # Add other versions as needed

# Iterate over each installed Python or PyPy version and run the benchmarks
for VERSION in "${PYTHON_VERSIONS[@]}"; do
    if command -v $VERSION &>/dev/null; then
        PYTHON_PATH=$($VERSION -c "import sys; print(sys.executable)")
        echo "Running benchmarks for $VERSION at $PYTHON_PATH..."
        run_benchmarks $VERSION $PYTHON_PATH
    else
        echo "$VERSION is not installed. Skipping."
    fi
done

echo "Benchmarking complete for all versions."
