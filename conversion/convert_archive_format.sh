#! /bin/bash

SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
storagePath="$(pwd)"
storageDir="$storagePath/.cb-scripts"
logDir="$storageDir/${SCRIPT_NAME%.*}/logs"
archiveDir="$storageDir/${SCRIPT_NAME%.*}/archive_old"
errorDir="$storageDir/${SCRIPT_NAME%.*}/error"
mkdir -p "$logDir"
mkdir -p "$archiveDir"
mkdir -p "$errorDir"

echo "Please wait while we gather some information about your files."
echo

# Get metrics before running any operations
totalCbrBefore=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
totalCbzBefore=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
totalOtherBefore=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" -not -iname "*.log" | wc -l)
totalSumBefore=$((totalCbrBefore+totalCbzBefore+totalOtherBefore))
totalFilesBefore=$(find . -maxdepth 2 -type f -not -iname "*.log" | wc -l)
totalFilesBeforeList=$(find . -maxdepth 2 -type f | sort)

# Print data to console
echo "There are a total of ${totalCbrBefore} cbr files."
echo "There are a total of ${totalCbzBefore} cbz files."
echo "There are a total of ${totalOtherBefore} other files that will be ignored."
echo


# Check that the total sum equals the total count as a checksum
if [[ $totalSumBefore -ne totalFilesBefore ]]; then

    echo "Error: Checksum mismatch. Sum ${totalSumBefore} does not match files ${totalFilesBefore}. Exiting script."
    exit

fi

# Create a log of all files before operations
echo "${totalFilesBeforeList}">$logDir/before_conversion_files_$(date +%s.%3N).log

# User menu
PS3="Enter a number for your selection: "

if [[ $totalCbrBefore == 0 ]] && [[ $totalCbzBefore == 0 ]]; then

    echo "No files found to convert. Exiting script."
    exit

elif [[ $totalCbrBefore == 0 ]] && [[ $totalCbzBefore != 0 ]]; then

    echo "You have {$totalCbzBefore} cbz files and ${totalCbrBefore} cbr files."
    echo "Do you wish to convert all cbz files to cbr?"

    select rx in "Convert to cbr (not recommended)" "Cancel and exit"; do

        case $rx in
            'Convert to cbr (not recommended)' ) echo "You chose to convert all cbz files to cbr."; conversionFormat=cbr; break;;
            'Cancel and exit' ) echo "You have chosen to exit the script with no actions."; exit;;
        esac

    done

elif [[ $totalCbrBefore != 0 ]] && [[ $totalCbzBefore == 0 ]]; then

    echo "You have ${totalCbrBefore} cbr files and ${totalCbzBefore} cbz files."
    echo "Do you wish to convert all cbr files to cbz?"

    select rx in "Convert to cbz (recommended)" "Cancel and exit"; do

        case $rx in
            'Convert to cbz (recommended)' ) echo "You chose to convert all cbr files to cbz."; conversionFormat=cbz; break;;
            'Cancel and exit' ) echo "You have chosen to exit the script with no actions."; exit;;
        esac

    done

else

    echo "You have ${totalCbrBefore} cbr files and ${totalCbzBefore} cbz files."
    echo "You may choose to convert all files to either cbr or cbz."

    select rx in "Convert to cbr (not recommended)" "Convert to cbz (recommended)" "Cancel and exit"; do

        case $rx in
            'Convert to cbr (not recommended)' ) echo "You have chosen to convert all cbz files to cbr"; conversionFormat=cbr; break;;
            'Convert to cbz (recommended)' ) echo "You chose to convert all cbr files to cbz."; conversionFormat=cbz; break;;
            'Cancel and exit' ) echo "You have chosen to exit the script with no actions."; exit;;
        esac

    done

fi

SECONDS=0

if [[ $conversionFormat == cbz ]]; then

    # Loop through all cbr files in directories one level deep
    for f in */*.cbr; do

        echo "Processing ${f}"

        if unrar t -idq "${f}"; then

            mkdir -p "$archiveDir/$(dirname "${f}")/" # Create a directory to store the old files in case we need to roll back
            unrar e -idq "${f}" "${f%.*}/" # Unrar the file to a temporary directory
            zip -j -9 -q "${f%.*}.cbz" "${f%.*}"/* # Zip the files in the temporary directory to the root of a cbz file
            rm -r "${f%.*}/" # Remove the temporary directory
            mv "${f}" "$archiveDir/$(dirname "${f}")/" # Archive the old file

        else # If it isn't a cbr file or is corrupt
            mv "${f}" "$(dirname "${f}")/error/" # Move the file to the error directory

        fi

    done

elif [[ $conversionFormat == cbr ]];then

    # Loop through all cbr files in directories one level deep
    for f in */*.cbz; do

        echo "Processing ${f}"

        if unzip -t -q "${f}"; then

            mkdir -p "$archiveDir/$(dirname "${f}")/" # Create a directory to store the old files in case we need to roll back
            unzip -j -q "${f}" -d "${f%.*}/" > /dev/null 2>&1 # Unzip the file to a temporary directory
            echo which
            rar a -idq -ep "${f%.*}.cbr" "${f%.*}"/* # Rar the files in the temporary directory to the root of a cbr file
            rm -r "${f%.*}/" # Remove the temporary directory
            mv "${f}" "$archiveDir/$(dirname "${f}")/" # Archive the old file

        else # If it isn't a cbr file or is corrupt

            mv "${f}" "$(dirname "${f}")/error/" # Move the file to the error directory
        fi

    done

else

    echo "Error: something has gone wrong. The file is likely corrupt or isn't a cbr or cbz file."
    exit

fi

let "hours=SECONDS/3600"
let "minutes=(SECONDS%3600)/60"
let "seconds=(SECONDS%3600)%60"
elapsedTime=$(printf "%02d" $hours):$(printf "%02d" $minutes):$(printf "%02d" $seconds)
echo $elapsedTime

echo "Completed in $elapsedTime."

#     echo
    
#         case $REPLY in
#             [Yy] )
#                 echo "Added to queue. Files that match '$title' will be removed from your cbr/cbz files."
#                 expList+=( "${expression}" ) # Add expression to the list to be run.
#                 tmpFileList+=( "${loopFileList[@]}" ) # Add list of cbr/cbz files
#                 # sleep 2
#                 break
#                 ;;
#             [Nn] )
#                 echo "Skipping. Files matching '$title' will not be removed from your cbr/cbz files."
#                 # sleep 2
#                 break
#                 ;;
#             [Xx] )
#                 echo "Exiting the script."
#                 exit
#                 ;;
#             * )
#                 echo "I didn't understand that. Please choose an option."
#                 read -r -t 0.001
#                 ;;
#         esac

# done
# read -p " Press "Z" to convert all files to cbz or "R" to convert all files to cbr." -rsn1

# # Loop through all cbr files in directories one level deep
# for f in */*.cbr; do
#     echo "Processing ${f}"
#     if unrar t -idq "${f}" # Check if file is a cbr regardless of extension
#     then
#         mkdir -p "$storageDir//cbr/$(dirname "${f}")/" # Create a directory to store the old files in case we need to roll back
#         unrar e -idq "${f}" "${f%.*}/" # Unrar the file to a temporary directory
#         if [[ $f == *.cbz ]] # Check if the file has the wrong extension (cbz)
#         then
#             mkdir -p "$(dirname "${f}")/actuallyCbr/" # Create a directory to store files with the wrong extension
#             mv "${f}" "$(dirname "${f}")/actuallyCbr/" # Move the file with the wrong extension
#         elif [[ $f == *.cbr ]] # Check if the file has the right extension
#         then
#             mv "${f%.*}".cbr "$(dirname "${f}")/complete/" # Move the file to the complete directory
#         fi
#         zip -j -9 -q "${f%.*}.cbz" "${f%.*}"/* # Zip the files in the temporary directory to the root of a cbz file
#         rm -r "${f%.*}/" # Remove the temporary directory
#     elif unzip -t -q "${f}" # Check if the file is a cbz regardless of extension
#     then
#         if [[ $f == *.cbr ]] # Check if the file has the wrong extension (cbr)
#         then
#             mv "${f}" "${f%.*}".cbz # Change the filename to have the proper extension (cbz)
#             mkdir -p "$(dirname "${f}")/complete/" # Create a directory to store the old files
#             touch "$(dirname "${f}")/complete/$(basename "${f}")" # Create a dummy file with the cbr filename so our count matches after completion
#         fi
#     else # If it isn't a cbr or cbz file regardless of extension
#         mkdir -p "$(dirname "${f}")/error" # Create an error directory
#         mv "${f}" "$(dirname "${f}")/error/" # Move the file to the error directory
#     fi
# done

# # Collect metrics after running operations to give us the ability to validate the numbers work out
# totalCbrAfter=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
# totalCbzAfter=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
# totalCbzErrors=$(find . -maxdepth 3 -type f -path "*/error/*.cbz" | wc -l)
# totalCbzNew=$((totalCbzAfter-totalCbzBefore+totalCbzErrors))
# totalOtherAfter=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" -not -iname "*.log" | wc -l)
# totalCbrComplete=$(find . -maxdepth 3 -type f -path "*/complete/*.cbr" | wc -l)
# totalCbrCompleteList=$(find . -maxdepth 3 -type f -path "*/complete/*.cbr" | sort)
# totalFileErrors=$(find . -maxdepth 3 -type f -path "*/error/*" | wc -l)
# totalFileErrorsList=$(find . -maxdepth 3 -type f -path "*/error/*" | sort)
# totalSumAfter=$((totalCbrAfter+totalCbzAfter+totalOtherAfter))
# totalFilesAfter=$(find . -maxdepth 2 -type f -not -iname "*.log" | wc -l)
# totalFilesAfterWithErrors=$((totalFilesAfter+totalFileErrors))
# totalFilesAfterList=$(find . -maxdepth 2 -type f -not -iname "*.log")

# # Print data to console
# echo "CBR Before: ${totalCbrBefore}"
# echo "CBR After: ${totalCbrAfter}"
# echo "CBZ Before: ${totalCbzBefore}"
# echo "CBZ After: ${totalCbzAfter}"
# echo "Other Files Before: ${totalOtherBefore}"
# echo "Other Files After: ${totalOtherAfter}"

# # Write completed cbr and error logs. TODO: Write log of all files and log of misnamed files.
# echo "Writing log of ${totalCbrComplete} archived CBR files to cbr-complete.log"
# echo "${totalCbrCompleteList}">cbr-complete.log
# echo "Writing log of ${totalFileErrors} archived error files to errors.log"
# echo "${totalFileErrorsList}">errors.log

# # Reiterate the checksum from before operations
# echo "Checksum ${totalSumBefore} matched total files ${totalFilesBefore} before running"

# # Check that the total sum after operations equals the total count as a checksum
# if [[ $totalSumAfter -ne totalFilesAfter ]] 
#     then
#     echo "Error: Checksum mismatch. Sum ${totalSumAfter} does not match files ${totalFilesAfter}"
# else
#     echo "Checksum ${totalSumAfter} matches total files ${totalFilesAfter} after running"   
# fi

# # Check that we have the expected number of new cbz files and that the total number of files before and after is the same. We don't want any missing files.
# if [[ $totalCbrComplete -ne totalCbzNew ]] || [[ $totalFilesBefore -ne $totalFilesAfterWithErrors ]]
#     then
#     echo "The total number of new CBZ files ${totalCbzNew} does not equal the total number of archived CBR files ${totalCbrComplete} or the total number of files before ${totalFilesBefore} does not equal the total number of files after ${totalFilesAfterWithErrors}"
#     echo "Please check the logs for more details"
#     exit
# else
#     echo "The total number of new CBZ files ${totalCbzNew} equals the total number of archived CBR files ${totalCbrComplete} and the total number of files before ${totalFilesBefore} equals the total number of files after ${totalFilesAfterWithErrors} accounting for ${totalFilesAfter} total files and ${totalFileErrors} errors"
# fi

# exit
