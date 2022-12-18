#! /bin/bash

# Get metrics before running any operations
totalCbrBefore=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
totalCbzBefore=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
totalOtherBefore=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" -not -iname "*.log" | wc -l)
totalSumBefore=$((totalCbrBefore+totalCbzBefore+totalOtherBefore))
totalFilesBefore=$(find . -maxdepth 2 -type f -not -iname "*.log" | wc -l)
totalFilesBeforeList=$(find . -maxdepth 2 -type f | sort)

# Print data to console
echo "CBR Before: ${totalCbrBefore}"
echo "CBZ Before: ${totalCbzBefore}"
echo "Other Files Before: ${totalOtherBefore}"

# Check that the total sum equals the total count as a checksum
if [[ $totalSumBefore -ne totalFilesBefore ]]
    then
    echo "Error: Checksum mismatch. Sum ${totalSumBefore} does not match files ${totalFilesBefore}"
    exit
fi
echo "Checksum ${totalSumBefore} matches total files ${totalFilesBefore}"

# Create a log of all files before operations
echo "writing log of all files before running script to all-files-before.log"
echo "${totalFilesBeforeList}">all-files-before.log

# Loop through all cbr and cbz files in directories one level deep
for f in */*.cb*; do
    echo "Processing ${f}"
    if unrar t -idq "${f}" # Check if file is a cbr regardless of extension
    then
        mkdir -p "$(dirname "${f}")/complete/" # Create a directory to store the old files in case we need to roll back
        unrar e -idq "${f}" "${f%.*}/" # Unrar the file to a temporary directory
        if [[ $f == *.cbz ]] # Check if the file has the wrong extension (cbz)
        then
            mkdir -p "$(dirname "${f}")/actuallyCbr/" # Create a directory to store files with the wrong extension
            mv "${f}" "$(dirname "${f}")/actuallyCbr/" # Move the file with the wrong extension
        elif [[ $f == *.cbr ]] # Check if the file has the right extension
        then
            mv "${f%.*}".cbr "$(dirname "${f}")/complete/" # Move the file to the complete directory
        fi
        zip -j -9 -q "${f%.*}.cbz" "${f%.*}"/* # Zip the files in the temporary directory to the root of a cbz file
        rm -r "${f%.*}/" # Remove the temporary directory
    elif unzip -t -q "${f}" # Check if the file is a cbz regardless of extension
    then
        if [[ $f == *.cbr ]] # Check if the file has the wrong extension (cbr)
        then
            mv "${f}" "${f%.*}".cbz # Change the filename to have the proper extension (cbz)
            mkdir -p "$(dirname "${f}")/complete/" # Create a directory to store the old files
            touch "$(dirname "${f}")/complete/$(basename "${f}")" # Create a dummy file with the cbr filename so our count matches after completion
        fi
    else # If it isn't a cbr or cbz file regardless of extension
        mkdir -p "$(dirname "${f}")/error" # Create an error directory
        mv "${f}" "$(dirname "${f}")/error/" # Move the file to the error directory
    fi
done

# Collect metrics after running operations to give us the ability to validate the numbers work out
totalCbrAfter=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
totalCbzAfter=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
totalCbzErrors=$(find . -maxdepth 3 -type f -path "*/error/*.cbz" | wc -l)
totalCbzNew=$((totalCbzAfter-totalCbzBefore+totalCbzErrors))
totalOtherAfter=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" -not -iname "*.log" | wc -l)
totalCbrComplete=$(find . -maxdepth 3 -type f -path "*/complete/*.cbr" | wc -l)
totalCbrCompleteList=$(find . -maxdepth 3 -type f -path "*/complete/*.cbr" | sort)
totalFileErrors=$(find . -maxdepth 3 -type f -path "*/error/*" | wc -l)
totalFileErrorsList=$(find . -maxdepth 3 -type f -path "*/error/*" | sort)
totalSumAfter=$((totalCbrAfter+totalCbzAfter+totalOtherAfter))
totalFilesAfter=$(find . -maxdepth 2 -type f -not -iname "*.log" | wc -l)
totalFilesAfterWithErrors=$((totalFilesAfter+totalFileErrors))
totalFilesAfterList=$(find . -maxdepth 2 -type f -not -iname "*.log")

# Print data to console
echo "CBR Before: ${totalCbrBefore}"
echo "CBR After: ${totalCbrAfter}"
echo "CBZ Before: ${totalCbzBefore}"
echo "CBZ After: ${totalCbzAfter}"
echo "Other Files Before: ${totalOtherBefore}"
echo "Other Files After: ${totalOtherAfter}"

# Write completed cbr and error logs. TODO: Write log of all files and log of misnamed files.
echo "Writing log of ${totalCbrComplete} archived CBR files to cbr-complete.log"
echo "${totalCbrCompleteList}">cbr-complete.log
echo "Writing log of ${totalFileErrors} archived error files to errors.log"
echo "${totalFileErrorsList}">errors.log

# Reiterate the checksum from before operations
echo "Checksum ${totalSumBefore} matched total files ${totalFilesBefore} before running"

# Check that the total sum after operations equals the total count as a checksum
if [[ $totalSumAfter -ne totalFilesAfter ]] 
    then
    echo "Error: Checksum mismatch. Sum ${totalSumAfter} does not match files ${totalFilesAfter}"
else
    echo "Checksum ${totalSumAfter} matches total files ${totalFilesAfter} after running"   
fi

# Check that we have the expected number of new cbz files and that the total number of files before and after is the same. We don't want any missing files.
if [[ $totalCbrComplete -ne totalCbzNew ]] || [[ $totalFilesBefore -ne $totalFilesAfterWithErrors ]]
    then
    echo "The total number of new CBZ files ${totalCbzNew} does not equal the total number of archived CBR files ${totalCbrComplete} or the total number of files before ${totalFilesBefore} does not equal the total number of files after ${totalFilesAfterWithErrors}"
    echo "Please check the logs for more details"
    exit
else
    echo "The total number of new CBZ files ${totalCbzNew} equals the total number of archived CBR files ${totalCbrComplete} and the total number of files before ${totalFilesBefore} equals the total number of files after ${totalFilesAfterWithErrors} accounting for ${totalFilesAfter} total files and ${totalFileErrors} errors"
fi

exit
