#/bin/env bash

# Build sceptre package

# Build the directory structure required

rm -rf stacker
mkdir -p stacker
cp -Rp src/stacker/* stacker

mkdir -p stacker/templates
cp -Rp src/cfn/* stacker/templates/
