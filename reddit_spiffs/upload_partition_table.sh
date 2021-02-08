#!/bin/bash

# Bomb out if an error occurs
set -e

THIS_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$THIS_SCRIPTS_DIR"
export PATH="$PATH:$THIS_SCRIPTS_DIR"

PROJECT_ROOT="$(dirname "$THIS_SCRIPTS_DIR")"
source "$PROJECT_ROOT/scripts/scripting_functions.sh"

help() {
  msg-info "
    Uploads a partition table to a connected ESP32
    Usage: upload_partition_table.sh [--help]
      --help: Show this message
  "
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  help
  exit
fi

PARTITIONS_CSV_PATH=''
if [[ -f "$PROJECT_ROOT/partitions.csv" ]]; then
  PARTITIONS_CSV_PATH="$PROJECT_ROOT/partitions.csv"
  cd "$PROJECT_ROOT"
fi

if [[ -f "$PARTITIONS_CSV_PATH" ]]; then
  msg-success "Found '$PARTITIONS_CSV_PATH'"
else
  msg-error "Could not find '$PARTITIONS_CSV_PATH'"
fi

msg-info "Building the table binary..."
idf.py partition_table

msg-info "Uploading the partition table..."
esptool.py -b 460800 --before default_reset --after hard_reset write_flash 0x8000 build/partition_table/partition-table.bin

msg-success "Everything was completed successfully"
