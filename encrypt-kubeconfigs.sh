#!/usr/bin/env bash

# Script to encrypt kubeconfig files with a password
# Usage: ./encrypt-kubeconfigs.sh <password>

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <password>"
  echo "Example: $0 my-secure-password"
  exit 1
fi

PASSWORD="$1"
INPUT_DIR="kubeconfigs"
OUTPUT_DIR="kubeconfigs-encrypted"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "================================================"
echo "Encrypting kubeconfig files"
echo "================================================"
echo ""

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
  echo "✗ ERROR: Directory $INPUT_DIR not found"
  echo "Please run ./generate-kubeconfigs.sh first"
  exit 1
fi

# Count files
file_count=$(ls -1 "$INPUT_DIR"/*.yaml 2>/dev/null | wc -l)
if [ "$file_count" -eq 0 ]; then
  echo "✗ ERROR: No .yaml files found in $INPUT_DIR"
  exit 1
fi

# Encrypt each kubeconfig file
for input_file in "$INPUT_DIR"/*.yaml; do
  filename=$(basename "$input_file")
  output_file="$OUTPUT_DIR/${filename}.enc"

  echo "Encrypting: $filename"

  # Encrypt the file using pbkdf2 key derivation
  openssl aes-256-cbc -a -salt -pbkdf2 -pass "pass:$PASSWORD" -in "$input_file" -out "$output_file"

  echo "  ✓ Created: $output_file"
done

echo ""
echo "================================================"
echo "Encryption complete!"
echo "================================================"
echo "Encrypted files are in: $OUTPUT_DIR/"
echo ""
echo "To decrypt a file, use:"
echo "  ./decrypt-kubeconfig.sh <encrypted-file> <password>"
echo ""
echo "Example:"
echo "  ./decrypt-kubeconfig.sh $OUTPUT_DIR/participant-1-kubeconfig.yaml.enc $PASSWORD"
