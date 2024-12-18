#!/bin/bash

# Define the root directory (assuming the script is placed in the root directory)
ROOT_DIR=$(dirname "$0")

# Check if the required command is available
command -v envsubst >/dev/null 2>&1 || { echo >&2 "envsubst is required but it's not installed. Aborting."; exit 1; }

# Source the .env file from the root directory
if [[ -f "${ROOT_DIR}/.env" ]]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # Ignore comments and empty lines
    if [[ ! "$line" =~ ^# && ! -z "$line" ]]; then
      export "$line"
    fi
  done < "${ROOT_DIR}/.env"
else
  echo ".env file not found in the root directory. Aborting."
  exit 1;
fi

# Function to process a single YAML file
process_file() {
  local input_file="$1"
  local output_file="${input_file%.*}.env.${input_file##*.}"
  
  # Use envsubst to replace environment variables and write to the new file
  envsubst < "$input_file" > "$output_file"

  echo "Processed $input_file -> $output_file"
}

find . -maxdepth 1 -type f -name "*.env.yaml" -exec rm -f {} +
find . -maxdepth 1 -type f -name "*.env.yml" -exec rm -f {} +

# Process all .yaml and .yml files in the current directory
for yaml_file in *.yaml *.yml; do
  # Skip files that already match the .env.yaml or .env.yml pattern
  if [[ "$yaml_file" != *.env.yaml && "$yaml_file" != *.env.yml ]]; then
    process_file "$yaml_file"
  fi
done
