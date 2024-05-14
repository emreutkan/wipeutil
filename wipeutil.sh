#!/bin/bash

DEVICE=${@: -1}

# Dictionary of file signatures
declare -A file_signatures=(
    ["jpeg"]="\\xff\\xd8\\xff"
    ["png"]="\\x89\\x50\\x4e\\x47\\x0d\\x0a\\x1a\\x0a"
    ["gif"]="\\x47\\x49\\x46\\x38"
    ["tiff_le"]="\\x49\\x49\\x2a\\x00"
    ["tiff_be"]="\\x4d\\x4d\\x00\\x2a"
    ["bmp"]="\\x42\\x4d"
    ["pdf"]="%PDF-"
    ["doc"]="\\xd0\\xcf\\x11\\xe0\\xa1\\xb1\\x1a\\xe1"
    ["docx"]="\\x50\\x4b\\x03\\x04"
    ["xls"]="\\xd0\\xcf\\x11\\xe0\\xa1\\xb1\\x1a\\xe1"
    ["xlsx"]="\\x50\\x4b\\x03\\x04"
    ["ppt"]="\\xd0\\xcf\\x11\\xe0\\xa1\\xb1\\x1a\\xe1"
    ["pptx"]="\\x50\\x4b\\x03\\x04"
    ["rtf"]="\\x7b\\x5c\\x72\\x74\\x66\\x31"
    ["mp4"]="\\x00\\x00\\x00\\x18\\x66\\x74\\x79\\x70"
    ["avi"]="\\x52\\x49\\x46\\x46"
    ["mkv"]="\\x1a\\x45\\xdf\\xa3"
    ["mov"]="\\x00\\x00\\x00\\x14\\x66\\x74\\x79\\x70\\x71\\x74\\x20\\x20\\x20"
    ["flv"]="\\x46\\x4c\\x56"
)

# Function to scan for file signatures
scan_for_signatures() {
    for filetype in "${!file_signatures[@]}"; do
        signature=${file_signatures[$filetype]}
        echo "Scanning for $filetype files with signature $signature"
        if sudo od -An -v -t x1 "$DEVICE" | grep -a -q "$signature"; then
            echo "Warning: Found $filetype file signature on the disk"
        else
            echo "No $filetype file signatures found"
        fi
    done
}

# Function to print help message
print_help() {
    echo "Example: diskwiper.sh -wdd 0 /dev/sdX"
    echo " "
    echo "Options:"
    echo "  -h  Display this help message"
    echo " "
    echo "  -v  Verify the disk after wiping"
    echo "    -v 0 Verify that the media only has zeros"
    echo "    -v 1 Verify that the media only has ones"
    echo "    -v <pattern> Verify that the media only has the specified pattern (in hex)"
    echo " "
    echo " -wdd  Wipe the disk using dd"
    echo "    -wdd 0 Fill the media with zeros"
    echo "    -wdd 1 Fill the media with ones"
    echo "    -wdd <pattern> Fill the media with the specified pattern (in hex)"
    echo " "
    echo " -wshread Wipe the disk using shred"
    echo "    -wshread 1 wipe the disk using shred 1 time"
    echo "    -wshread <count> wipe the disk using shred <count> times"
    echo " "
    echo " -c Scan for file signatures on the disk after wiping (e.g., jpg, png, pdf)"
    echo " -cr  Check the randomness of the data on the disk"
    echo " "
    echo " -se Secure erase the disk (for supported SSDs)"
    echo " -sef Secure erase the disk using the enhanced method (for supported Sata SSDs)"
    echo " -senvme Secure erase the disk using the NVMe command (for supported Nvme SSDs)"
}

# Print the help message if the first argument is -h or if no arguments are provided
if [ "$1" == "-h" ] || [ $# -lt 3 ]; then
    print_help
    exit 0
fi

# Verify the disk based on the provided pattern if -v is passed
if [ "$1" == "-v" ]; then
    if [ -z "$2" ]; then
        echo "No verification pattern provided. Please specify 0, 1, or a hex pattern."
        exit 1
    fi

    PATTERN=$2
    echo "Verifying that the disk only has the pattern: $PATTERN"

    # Convert pattern to lowercase
    PATTERN=$(echo "$PATTERN" | tr 'A-F' 'a-f')

    # Check if the pattern is valid
    if ! [[ "$PATTERN" =~ ^[0-9a-fA-F]{2}$ ]]; then
        echo "Invalid pattern. Please provide a valid hex byte (00 to FF)."
        exit 1
    fi

    # Run the verification
    if sudo od -An -v -t x1 "$DEVICE" | grep -av " $PATTERN"; then
        echo "Verification failed: The disk contains other patterns than $PATTERN"
    else
        echo "Verification passed: The disk contains only the pattern $PATTERN"
    fi
fi

# Wipe the disk using dd based on the provided pattern if -wdd is passed
if [ "$1" == "-wdd" ]; then
    if [ -z "$2" ]; then
        echo "No wipe pattern provided. Please specify 0, 1, or a hex pattern."
        exit 1
    fi

    PATTERN=$2
    echo "Wiping the disk with pattern: $PATTERN"

    if [ "$PATTERN" == "0" ]; then
        sudo dd if=/dev/zero of="$DEVICE" bs=1M status=progress
    elif [ "$PATTERN" == "1" ]; then
        sudo dd if=<(yes '\x01' | tr -d '\n') of="$DEVICE" bs=1M status=progress
    else
        # Convert pattern to lowercase
        PATTERN=$(echo "$PATTERN" | tr 'A-F' 'a-f')

        # Check if the pattern is valid
        if ! [[ "$PATTERN" =~ ^[0-9a-fA-F]{2}$ ]]; then
            echo "Invalid pattern. Please provide a valid hex byte (00 to FF)."
            exit 1
        fi

        # Create a temporary file with the pattern
        TMPFILE=$(mktemp)
        yes "$PATTERN" | tr -d '\n' | head -c 1048576 > "$TMPFILE"
        sudo dd if="$TMPFILE" of="$DEVICE" bs=1M status=progress
        rm "$TMPFILE"
    fi
fi

# Wipe the disk using shred if -wshread is passed
if [ "$1" == "-wshread" ]; then
    if [ -z "$2" ]; then
        echo "No count provided for shred. Please specify the number of times to overwrite."
        exit 1
    fi

    COUNT=$2
    echo "Wiping the disk with shred $COUNT times"

    sudo shred -n "$COUNT" -v "$DEVICE"
fi

# Secure erase the disk if -se is passed
if [ "$1" == "-se" ]; then
    echo "Performing secure erase on the disk"

    sudo hdparm --user-master u --security-set-pass p "$DEVICE"
    sudo hdparm --user-master u --security-erase p "$DEVICE"
fi

# Secure erase the disk using the enhanced method if -sef is passed
if [ "$1" == "-sef" ]; then
    echo "Performing secure erase (enhanced) on the disk"

    sudo hdparm --user-master u --security-set-pass p "$DEVICE"
    sudo hdparm --user-master u --security-erase-enhanced p "$DEVICE"
fi

# Secure erase the disk using the NVMe command if -senvme is passed
if [ "$1" == "-senvme" ]; then
    echo "Performing secure erase using the NVMe command on the disk"

    sudo nvme format --ses=1 "$DEVICE"
fi

if [ "$1" == "-c" ]; then
    scan_for_signatures
fi

check_randomness() {
    echo "Checking the randomness of the data on the disk"
    sudo dd if="$DEVICE" bs=1M | ent
}
check_randomness_no_ent() {
    echo "Checking the randomness of the data on the disk"

    # Read the entire disk in 1MB blocks, process with od, and calculate byte frequencies with awk
    sudo dd if="$DEVICE" bs=1M | od -An -t x1 | tr -s ' ' '\n' | \
    awk '
    {
        freq[$1]++
        total++
    }
    END {
        entropy = 0
        expected_freq = total / 256
        chi_square = 0

        for (byte in freq) {
            p = freq[byte] / total
            entropy -= p * log(p) / log(2)
            chi_square += ((freq[byte] - expected_freq) ^ 2) / expected_freq
        }

        print "Entropy: " entropy " bits per byte"
        print "Chi-square: " chi_square
        print "Total bytes analyzed: " total
    }'
}

if [ "$1" == "-cr" ]; then
    check_randomness
fi
