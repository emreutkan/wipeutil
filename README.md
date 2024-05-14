# wipeutil

## Description
A Bash script to securely wipe disks using different methods and verify the data after wiping. It also provides functionality to scan for specific file signatures on the disk.

## Disclaimer
Use this script with caution. Ensure you specify the correct device to avoid data loss.

## Usage

```bash
wipeutil.sh [OPTION] [PATTERN/COUNT] /dev/sdX
```

# Disk Wiping and Verification Script

## Options
- `-h` : Display help message
- `-v [PATTERN]` : Verify the disk after wiping
  - `0` : Verify that the media only has zeros
  - `1` : Verify that the media only has ones
  - `<pattern>` : Verify that the media only has the specified pattern (in hex)
- `-wdd [PATTERN]` : Wipe the disk using `dd`
  - `0` : Fill the media with zeros
  - `1` : Fill the media with ones
  - `<pattern>` : Fill the media with the specified pattern (in hex)
- `-wshread [COUNT]` : Wipe the disk using `shred`
  - `1` : Wipe the disk using shred 1 time
  - `<count>` : Wipe the disk using shred `<count>` times
- `-c` : Scan for file signatures on the disk after wiping (e.g., jpg, png, pdf)
- `-cr` : Check the randomness of the data on the disk
- `-se` : Secure erase the disk (for supported SSDs)
- `-sef` : Secure erase the disk using the enhanced method (for supported SATA SSDs)
- `-senvme` : Secure erase the disk using the NVMe command (for supported NVMe SSDs)


## Required Libraries:
- bash
- sudo
- od
- grep
- dd
- shred
- hdparm
- nvme (for NVMe commands)
