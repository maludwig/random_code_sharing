#!/bin/bash

# Bomb out if an error occurs
set -e

THIS_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$THIS_SCRIPTS_DIR"
export PATH="$PATH:$THIS_SCRIPTS_DIR"

PROJECT_ROOT="$(dirname "$THIS_SCRIPTS_DIR")"
source "$PROJECT_ROOT/scripts/scripting_functions.sh"

cd "$PROJECT_ROOT"

help() {
  msg-info "
    Usage: flash_and_screen.sh [--help] [--port <DEVICE_PATH>] [--partitions <CSV_PATH>] [--data <DATA_DIRECTORY_PATH>]
      -p|--port: The port of the ESP32 to flash (ex. /dev/ttyUSB0), defaults to detection
      --partitions: The path to the partitions.csv file, this should be in your project root, adjacent to your 'build' folder
      --data: The directory containing the files you want in the SPIFFS image
      --help: Show this message
  "
}

# Default variables
DEVICE_PATH=''
PARTITIONS_CSV_PATH=''
if [[ -f "$PROJECT_ROOT/partitions.csv" ]]; then
  PARTITIONS_CSV_PATH="$PROJECT_ROOT/partitions.csv"
fi

SPIFFS_IMAGE_PATH="$PROJECT_ROOT/build/spiffs.bin"
DATA_DIR="$PROJECT_ROOT/data"

while (( $# > 0 )); do
  case $1 in
    --data)
      DATA_DIR="$2"
      shift
      ;;
    --partitions)
      PARTITIONS_CSV_PATH="$2"
      shift
      ;;
    -p|--port)
      DEVICE_PATH="$2"
      shift
      ;;
    -h|--help)
      help
      exit
      ;;
    *)
      help
      msg-error "Unknown parameter $1"
      exit 1
      ;;
  esac
  shift
done

if [[ "$DEVICE_PATH" == "" ]]; then
  msg-info "Finding device..."
  DEVICE_COUNT=0
  for POSSIBLE_DEVICE_PATH in /dev/cu.usbserial* /dev/ttyUSB*; do
    if [[ -e "$POSSIBLE_DEVICE_PATH" ]]; then
      DEVICE_PATH="$POSSIBLE_DEVICE_PATH"
      msg-info "Found device: $DEVICE_PATH"
      DEVICE_COUNT="$(( DEVICE_COUNT + 1))"
    fi
  done
  if (( $DEVICE_COUNT == 1 )); then
    msg-info "Device found: $DEVICE_PATH"
  elif (( $DEVICE_COUNT == 0 )); then
    msg-error "No device found."
    exit 1
  else
    msg-error "Multiple devices found, select one with '-p <PORT>'"
    exit 1
  fi
fi

msg-info "Finding partition size..."
if [[ -f "$PARTITIONS_CSV_PATH" ]]; then
  msg-success "Found '$PARTITIONS_CSV_PATH'"
else
  msg-error "Could not find '$PARTITIONS_CSV_PATH'"
  exit 1
fi

if STORAGE_PARTITION_DEF=`cat "$PARTITIONS_CSV_PATH" | sed -E 's/ //g' | grep -E '^storage,data,spiffs,'`; then
  msg-info "Found SPIFFS partition:"
  echo "$STORAGE_PARTITION_DEF"
  STORAGE_PARTITION_SIZE=`echo "$STORAGE_PARTITION_DEF" | awk -F, '{ print $5 }'`
  msg-info "Partition Size: $STORAGE_PARTITION_SIZE"
else
  msg-error "Could not find SPIFFS partition."
  exit 1
fi

mkdir -p "$(dirname "$SPIFFS_IMAGE_PATH")"
if [[ -f "$SPIFFS_IMAGE_PATH" ]]; then
  rm "$SPIFFS_IMAGE_PATH"
fi

msg-info "
  Partition Size: $STORAGE_PARTITION_SIZE
  Data Directory (content of image): $DATA_DIR
  SPIFFS Image Path: $SPIFFS_IMAGE_PATH
"

msg-info "Building SPIFFS image..."
if "$THIS_SCRIPTS_DIR/spiffsgen.py" "$STORAGE_PARTITION_SIZE" "$DATA_DIR" "$SPIFFS_IMAGE_PATH"; then
  msg-success "Successfully built SPIFFS image"
  ls -la "$SPIFFS_IMAGE_PATH"
else
  msg-error "Failed to build SPIFFS image, is the ESP-IDF active?"
  exit 1
fi

msg-info "Flashing image..."
if esptool.py -p "$DEVICE_PATH" -b 460800 --before default_reset --after hard_reset write_flash 0x110000 "$SPIFFS_IMAGE_PATH"; then
  msg-success "Successfully flashed device"
else
  msg-error "Failed to flash image to device"
  exit 1
fi

msg-info "Connecting to serial device, use 'Ctrl+a Ctrl+k' to quit..."
screen "$DEVICE_PATH" 115200 -h 2000
msg-success "Everything completed successfully"
