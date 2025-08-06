#!/bin/bash

echo "=== Debug Hook Variables ==="
echo "All arguments: $@"
echo "Arg 1: $1"
echo "Arg 2: $2" 
echo "PWD: $PWD"
echo "filePath env: $filePath"
echo "FILE_PATH env: $FILE_PATH"
echo ""
echo "All environment variables containing 'file' or 'path':"
printenv | grep -i -E '(file|path)' | head -20
echo ""
echo "All environment variables:"
printenv | head -30