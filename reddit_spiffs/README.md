# reddit_spiffs

For someone having trouble with SPIFFS on Reddit to use. I strugged for days. Hopefully this works for you.

## Usage:

This script assumes that you have a project in a directory on your computer.
The project should have roughly the following structure:

```
PROJECT_ROOT/
  build/
  data/
  partitions.csv
  platformio.ini
  sdkconfig
  src/
  test/
```

Copy this folder into a new scripts directory:
```bash
cd random_code_sharing
mkdir <PROJECT_ROOT>/scripts
cp reddit_spiffs/* <PROJECT_ROOT>/scripts/
cp scripts/* <PROJECT_ROOT>/scripts/
```

Then upload your partition table csv (see upload_partition_table.sh).

```bash
cd <PROJECT_ROOT>
./scripts/upload_partition_table.sh --help
```

Then make a data/ directory in your project, and put a file into it:

```bash
mkdir <PROJECT_ROOT>/data
cd <PROJECT_ROOT>/data
echo 'Hello World' > hello.txt
cd <PROJECT_ROOT>
./scripts/flash_and_screen.sh --help
```

### `upload_partition_table.sh`

Uploads the partition table to the device (see example partitions.csv)

### `flash_and_screen.sh`

Builds an SPIFFS image from the "data" directory, then flashes that image onto an ESP32,
then uses "screen" to monitor the device.

### `spiffsgen.py`

From Espressif.

### `partitions.csv`

An example partitions definition file, copy it to `<PROJECT_ROOT>/partitions.csv`.
