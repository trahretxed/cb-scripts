#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo $SCRIPT_DIR
echo $PWD

# for f in */*.cbr; do
#     if unzip -t -q "${f}" > /dev/null 2>&1; then
#         echo "${f}"
#     fi
# done
# for f in */*.cbz; do
#     if unrar t -idq "${f}" > /dev/null 2>&1; then
#         echo "${f}"
#     fi
# done