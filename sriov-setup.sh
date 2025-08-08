#!/bin/bash
# Script to setup SR-IOV on a NIC

# Aug 8, 2025
# Gaoyang Wei <yhyxwgy@gmail.com>
set -e

# Usage: sriov-setup.sh [-s] <nic>-<numvfs>-<macprefix>
#   -s: simulate only (dry-run), do not actually execute commands

DRYRUN=0

# Check for -s flag
if [ "$1" == "-s" ]; then
    DRYRUN=1
    shift
fi

# Parse arguments
IFS='-' read NIC NUMVFS MACPREFIX <<< "$1"

if [ -z "$NIC" ] || [ -z "$NUMVFS" ] || [ -z "$MACPREFIX" ]; then
    echo "[ERROR] Usage: $0 [-s] <nic>-<numvfs>-<macprefix>"
    exit 1
fi

echo "[INFO] Parsed arguments:"
echo "[INFO]   NIC       = $NIC"
echo "[INFO]   NUMVFS    = $NUMVFS"
echo "[INFO]   MACPREFIX = $MACPREFIX"
echo "[INFO]   DRYRUN    = $DRYRUN"

# Get vendor MAC prefix (first 3 bytes) from the physical NIC
VENDOR_PREFIX=$(cat /sys/class/net/$NIC/address | cut -d':' -f1-3 | tr -d ':')

echo "[INFO] Vendor MAC prefix detected: $VENDOR_PREFIX"

# Normalize and validate MAC prefix
NORMALIZED_MACPREFIX=$(echo "$MACPREFIX" | tr '[:upper:]' '[:lower:]' | tr -d ':')

if ! [[ "$NORMALIZED_MACPREFIX" =~ ^[0-9a-f]{4}$ ]]; then
    echo "[ERROR] Invalid MAC prefix format: '$MACPREFIX'"
    echo "        Accepted formats: a0b1, ef:ef (case-insensitive)"
    exit 1
fi

MACPREFIX_FMT="${NORMALIZED_MACPREFIX:0:2}:${NORMALIZED_MACPREFIX:2:2}"

# Enable the number of VFs
SRIOV_PATH="/sys/class/net/$NIC/device/sriov_numvfs"

echo "[INFO] Clearing existing SR-IOV config: echo 0 > $SRIOV_PATH"
if [ "$DRYRUN" -eq 0 ]; then
    echo 0 > "$SRIOV_PATH"
fi

if [ "$NUMVFS" -eq 0 ]; then
    echo "[INFO] NUMVFS is 0, nothing more to do."
    exit 0
fi

echo "[INFO] Setting SR-IOV VFs: echo $NUMVFS > $SRIOV_PATH"
if [ "$DRYRUN" -eq 0 ]; then
    echo "$NUMVFS" > "$SRIOV_PATH"
fi

# Assign MAC addresses
echo "[INFO] Generating MAC addresses:"
for ((i=0; i<NUMVFS; i++)); do
    HEX=$(printf "%02x" $((0xa0 + i)))  # MAC suffix part, starting from a0
    MAC="$(echo $VENDOR_PREFIX | sed 's/../&:/g; s/:$//'):$MACPREFIX_FMT:$HEX"
    echo "[INFO] VF $i: ip link set $NIC vf $i mac $MAC"
    if [ "$DRYRUN" -eq 0 ]; then
        ip link set "$NIC" vf "$i" mac "$MAC"
    fi
done

echo "[INFO] SR-IOV configuration complete."

