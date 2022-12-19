#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
storagePath="$(pwd)"
storageDir="$storagePath/.cb-scripts/"
mkdir -p "$storageDir"

cbrIsCbz=0
cbzIsCbr=0
isCorrupt=0
unset isCorruptList

for f in */*.cbr; do
    if unrar t -inul "${f}"; then
        continue
    elif unzip -tq "${f}" > /dev/null 2>&1; then
        echo "$(basename "${f}"): Should be a cbz. Renaming..."
        mv "${f}" "${f%.*}.cbz"
        ((cbrIsCbz++))
    else
        echo "$(basename "${f}"): File is corrupt."
        isCorruptList+="$(basename "$f")\n"
        ((isCorrupt++))
    fi
done
for f in */*.cbz; do
    if unzip -tq "${f}" > /dev/null 2>&1; then
        continue
    elif unrar t -inul "${f}"; then
        echo "$(basename "${f}"): Should be a cbr. Renaming..."
        mv "${f}" "${f%.*}.cbr"
        ((cbzIsCbr++))
    else
        echo "$(basename "${f}"): File is corrupt."
        isCorruptList+="$(basename "$f")\n"
        ((isCorrupt++))
    fi
done

echo "$(($cbrIsCbz+$cbzIsCbr)) files had the wrong extension."
echo "$cbrIsCbz files were renamed to cbz."
echo "$cbzIsCbr files were renamed to cbr."
echo "$isCorrupt files appear to be corrupt and will need to be repaired or replaced."
echo "Please run repair_corrupt.sh on the following files:"
echo -e $isCorruptList | sort | sed '/^[[:space:]]*$/d' | more -n 20

