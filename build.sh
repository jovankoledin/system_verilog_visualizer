#!/bin/bash

# --- Build Script for SV Grapher ---
# Usage: ./build.sh <input.sv> <outputname>
# Example: ./build.sh inputs/serdes_top.sv serdes

# 1. Input Validation
if [ "$#" -ne 2 ]; then
    echo "Error: Illegal number of parameters."
    echo "Usage: $0 <input.sv> <outputname>"
    echo "Example: $0 my_design/top.sv my_top_graph"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_BASE="$2"
OUTPUT_DIR="build"

# Ensure the build directory exists
mkdir -p "$OUTPUT_DIR"

echo "Processing input file: $INPUT_FILE"
echo "Generating output files with base name: $OUTPUT_DIR/$OUTPUT_BASE"

# 2. Run the SV Grapher script
# It reads the input file ($1) and outputs the DOT file to build/$2.dot
python3 src/sv_grapher.py "$INPUT_FILE" -o "$OUTPUT_DIR/$OUTPUT_BASE"

# Check if the python script ran successfully and created the DOT file
if [ $? -ne 0 ] || [ ! -f "$OUTPUT_DIR/$OUTPUT_BASE.dot" ]; then
    echo "Error: sv_grapher.py failed or did not create the DOT file."
    exit 1
fi

# 3. Convert the DOT file to PNG using the Graphviz 'dot' command
DOT_FILE="$OUTPUT_DIR/$OUTPUT_BASE.dot"
PNG_FILE="$OUTPUT_DIR/$OUTPUT_BASE.png"

dot -Tpng "$DOT_FILE" -o "$PNG_FILE"

# Check if the dot command ran successfully
if [ $? -ne 0 ]; then
    echo "Error: 'dot' command failed to generate $PNG_FILE. Is Graphviz installed?"
    exit 1
fi

echo "Successfully generated PNG image: $PNG_FILE"

# 4. Open the generated PNG image
xdg-open "$PNG_FILE"
