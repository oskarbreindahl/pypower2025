#!/bin/bash

# Function to compare two benchmark result files
comp_benchmarks() {
    PYTHON_VERSION1=$1
    PYTHON_VERSION2=$2 
    pyperformance compare $PYTHON_VERSION1.json $PYTHON_VERSION2.json
}

# List of installed Python and PyPy versions (full implementation names)
PYTHON_VERSIONS=("python3.9" "python3.12" "python3.13")  # Add other versions as needed

# Create/clear the comparison results file
COMPARISON_FILE="benchmark_comparisons.txt"
> $COMPARISON_FILE

# Iterate over all pairs of Python or PyPy versions and compare their benchmarks
for ((i=0; i<${#PYTHON_VERSIONS[@]}; i++)); do
    for ((j=i+1; j<${#PYTHON_VERSIONS[@]}; j++)); do
        VERSION1=${PYTHON_VERSIONS[$i]}
        VERSION2=${PYTHON_VERSIONS[$j]}
        
        echo "Comparing benchmarks for $VERSION1 and $VERSION2..." >> $COMPARISON_FILE
        comp_benchmarks $VERSION1 $VERSION2 >> $COMPARISON_FILE
        echo "-----------------------------------------------------" >> $COMPARISON_FILE
    done
done

echo "Benchmark comparisons complete. Results saved to $COMPARISON_FILE."
