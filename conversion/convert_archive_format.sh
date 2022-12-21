#! /bin/bash

# This script is intended to give the user the ability to convert a library of cbr or cbz files completely to one format or the other.
# We recommend using cbz, as cbr is a prorpietary format and more difficult to work with. It is also a pain because the IP holder doesn't allow his tools to be distributed.
# In addition, this script will also remove any paths inside the archives, moving all files to the root of the archive. Some readers have trouble with recursive folder structures and they provide no benefit.
# We recommend checking for corrupt files and replacing or fixing them before running this script. Any files that fail to be processed will be moved to an error directory.
# Please run the extension correction script before this script, as it does not handle files with the wrong extension (cbz files with cbr extensions and vice versa).
# Scripts to remove unwanted files can be run before or after this script.
# Scripts to convert locked or solid archives do not need to be run if converting to cbz. If converting to cbr, run that script before this one, as it will take less time.
# While it doesn't matter if you add metadata and mass renaming before or after this script, although it is recommended to do those steps last. Mass renaming must be done after adding metadata.


SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
runId=$( date +%s )
storagePath="$(pwd)"
storageDir="$storagePath/.cb-scripts"
logDir="$storageDir/${SCRIPT_NAME%.*}/logs"
archiveDir="$storageDir/${SCRIPT_NAME%.*}/archive/$runId"
errorDir="$storageDir/${SCRIPT_NAME%.*}/error/$runId"
mkdir -p "$logDir"
mkdir -p "$archiveDir"
mkdir -p "$errorDir"

# Start log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - Start $SCRIPT_NAME Run ID $runId">>$logDir/run_$(date +%Y%m%d).log

# Display basic info to user.
clear
echo "Please read the readme file before running these scripts as it contains information on the recommended order to proceed."
echo "This script is intended to convert all of your cbr or cbz files to one format."
echo "Using cbz is recommended over cbr, due to the proprietary nature of the cbr format."
read -n 1 -s -r -p "Press any key to continue"

clear
echo "Please wait while we gather some information about your files."
echo

# Get data before running operations
totalCbrBefore=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
totalCbzBefore=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
totalCbBefore=$((totalCbrBefore+totalCbzBefore))
totalOtherBefore=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" -not -iname "*.log" | wc -l)
totalSumBefore=$((totalCbrBefore+totalCbzBefore+totalOtherBefore))
totalFilesBefore=$(find . -maxdepth 2 -type f -not -iname "*.log" | wc -l)
totalFilesBeforeList=$(find . -maxdepth 2 -type f | sort)

# Log data before operations
echo "$(date +%Y%m%dT%H%M%S.%N%z) - Before: There are a total of ${totalCbrBefore} cbr files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - Before: There are a total of ${totalCbzBefore} cbz files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - Before: There are a total of ${totalCbBefore} archive files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - Before: There are a total of ${totalOtherBefore} other files that will be ignored.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - Before: The sum of archives and other files is ${totalSumBefore}.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - Before: There are a total of ${totalFilesBefore} files.">>$logDir/run_$(date +%Y%m%d).log
echo "${totalFilesBeforeList}">>$logDir/pre_conversion_files_$( date +%Y%m%dT%H%M%S.%N%z ).log

# Check that the total sum equals the total count as a checksum before continuing. We want to see if anything has gone wrong with our inputs.
if [[ $totalSumBefore -ne $totalFilesBefore ]]; then

    echo "Error: Checksum mismatch. Sum ${totalSumBefore} does not match files ${totalFilesBefore}. Exiting script."
    exit

fi

# User menu
PS3="Enter a number for your selection: "

# Check to see if no cbz or cbz are found.
if [[ $totalCbrBefore == 0 ]] && [[ $totalCbzBefore == 0 ]]; then

    echo "No files found to convert. Exiting script."
    exit

# Check to see if we only have cbr files.
elif [[ $totalCbrBefore == 0 ]] && [[ $totalCbzBefore != 0 ]]; then

    echo "You have {$totalCbzBefore} cbz files and ${totalCbrBefore} cbr files."
    echo "Do you wish to convert all cbz files to cbr?"

    select rzx in "Convert to cbr (not recommended)" "Cancel and exit"; do

        case $rzx in
            'Convert to cbr (not recommended)' ) echo "You chose to convert all cbz files to cbr."; conversionFormat=cbr; break;;
            'Cancel and exit' ) echo "You have chosen to exit the script with no actions."; exit;;
        esac

    done

# Check to see if we only have cbz files.
elif [[ $totalCbrBefore != 0 ]] && [[ $totalCbzBefore == 0 ]]; then

    echo "You have ${totalCbrBefore} cbr files and ${totalCbzBefore} cbz files."
    echo "Do you wish to convert all cbr files to cbz?"

    select rzx in "Convert to cbz (recommended)" "Cancel and exit"; do

        case $rzx in
            'Convert to cbz (recommended)' ) echo "You chose to convert all cbr files to cbz."; conversionFormat=cbz; break;;
            'Cancel and exit' ) echo "You have chosen to exit the script with no actions."; exit;;
        esac

    done

# We apparently have a mixed library.
else

    echo "You have ${totalCbrBefore} cbr files and ${totalCbzBefore} cbz files."
    echo "You may choose to convert all files to either cbr or cbz."

    select rzx in "Convert to cbr (not recommended)" "Convert to cbz (recommended)" "Cancel and exit"; do

        case $rzx in
            'Convert to cbr (not recommended)' ) echo "You have chosen to convert all cbz files to cbr"; conversionFormat=cbr; break;;
            'Convert to cbz (recommended)' ) echo "You chose to convert all cbr files to cbz."; conversionFormat=cbz; break;;
            'Cancel and exit' ) echo "You have chosen to exit the script with no actions."; exit;;
        esac

    done

fi

# Start counting so we can get the total time it takes to convert the library.
SECONDS=0

# Run when converting to cbz.
if [[ $conversionFormat == cbz ]]; then

    # Loop through all cbr files in directories one level deep
    for f in */*.cbr; do

        echo "Processing ${f}"

        if unrar t -idq "${f}"; then

            mkdir -p "$archiveDir/$(dirname "${f}")/" # Create a directory to store the old files in case we need to roll back
            mkdir -p "$errorDir/$(dirname "${f}")/"
            unrar e -idq "${f}" "${f%.*}/" # Unrar the file to a temporary directory
            zip -j -9 -q "${f%.*}.cbz" "${f%.*}"/* # Zip the files in the temporary directory to the root of a cbz file
            rm -r "${f%.*}/" # Remove the temporary directory
            mv "${f}" "$archiveDir/$(dirname "${f}")/" # Archive the old file

        else # If it isn't a cbr file or is corrupt
            mv "${f}" "$errorDir/$(dirname "${f}")/" # Move the file to the error directory

        fi

    done

# Run when converting to cbr.
elif [[ $conversionFormat == cbr ]];then

    # Loop through all cbr files in directories one level deep
    for f in */*.cbz; do

        echo "Processing ${f}"

        if unzip -t -q "${f}" > /dev/null 2>&1; then

            mkdir -p "$archiveDir/$(dirname "${f}")/" # Create a directory to store the old files in case we need to roll back
            mkdir -p "$errorDir/$(dirname "${f}")/"
            unzip -j -q "${f}" -d "${f%.*}/" > /dev/null 2>&1 # Unzip the file to a temporary directory
            rar a -idq -ep "${f%.*}.cbr" "${f%.*}"/* # Rar the files in the temporary directory to the root of a cbr file
            rm -r "${f%.*}/" # Remove the temporary directory
            mv "${f}" "$archiveDir/$(dirname "${f}")/" # Archive the old file

        else # If it isn't a cbr file or is corrupt

            mv "${f}" "$errorDir/$(dirname "${f}")/" # Move the file to the error directory
        fi

    done

# I don't know how we got here. It should be impossible.
else

    echo "Error: something has gone wrong. The file is likely corrupt or isn't a cbr or cbz file."
    exit

fi

# Get data after running operations
totalCbrAfter=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
totalCbzAfter=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
totalCbAfter=$((totalCbrAfter+totalCbzAfter))
totalOtherAfter=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" -not -iname "*.log" | wc -l)
totalSumAfter=$((totalCbrAfter+totalCbzAfter+totalOtherAfter))
totalFilesAfter=$(find . -maxdepth 2 -type f -not -iname "*.log" | wc -l)
totalArchivedCbr=$(find $archiveDir -maxdepth 2 -type f -path "*/*.cbr" | wc -l)
totalArchivedCbz=$(find $archiveDir -maxdepth 2 -type f -path "*/*.cbz" | wc -l)
totalErrorCbr=$(find $errorDir -maxdepth 2 -type f -path "*/*.cbr" | wc -l)
totalErrorCbz=$(find $errorDir -maxdepth 2 -type f -path "*/*.cbz" | wc -l)
totalCbrNew=$((totalCbrAfter-totalCbrBefore))
totalCbzNew=$((totalCbzAfter-totalCbzBefore))
totalCbrNewPlusErrors=$((totalCbrNew+totalErrorCbz))
totalCbzNewPlusErrors=$((totalCbzNew+totalErrorCbr))
totalFilesAfterList=$(find . -maxdepth 2 -type f | sort)
totalArchivedFilesList=$(find $archiveDir -maxdepth 2 -type f | sort)
totalErrorFilesList=$(find $errorDir -maxdepth 2 -type f | sort)

# # Log data after operations
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalCbrAfter} cbr files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalCbzAfter} cbz files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalCbAfter} archive files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalOtherAfter} other files that will be ignored.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: The sum of archives and other files is ${totalSumAfter}.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalArchivedCbr} archived cbr files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalArchivedCbz} archived cbz files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalErrorCbr} error cbr files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalErrorCbz} error cbz files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalCbrNew} new cbr files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalCbzNew} new cbz files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalCbrNewPlusErrors} new cbr files plus cbz error files.">>$logDir/run_$(date +%Y%m%d).log
echo "$(date +%Y%m%dT%H%M%S.%N%z) - After: There are a total of ${totalCbzNewPlusErrors} new cbz files plus cbr error files.">>$logDir/run_$(date +%Y%m%d).log
echo "${totalFilesAfterList}">>$logDir/post_conversion_files_$( date +%Y%m%dT%H%M%S.%N%z ).log
echo "${totalArchivedFilesList}">>$logDir/archived_files_$( date +%Y%m%dT%H%M%S.%N%z ).log
echo "${totalErrorFilesList}">>$logDir/error_files_$( date +%Y%m%dT%H%M%S.%N%z ).log

# Check that the total sum equals the total count as a checksum before continuing. We want to see if anything has gone wrong with our inputs.
if [[ $totalSumAfter -ne $totalFilesAfter ]]; then

    echo "Error: Checksum mismatch. Sum ${totalSumBefore} does not match files ${totalFilesBefore}. Exiting script."
    exit

fi

# Check that the total sum equals the total count as a checksum before continuing. We want to see if anything has gone wrong with our inputs.
if [[ $totalFilesBefore -ne $((totalFilesAfter+totalErrorCbr+totalErrorCbz)) ]]; then

    echo "Error: Totals files before and after do not match. Before there were $totalFilesBefore files and after there are $((totalFilesAfter+totalErrorCbr+totalErrorCbz)) files. Please see the logs to find the missing files. Exiting script."
    exit

fi

# Check that the total sum equals the total count as a checksum before continuing. We want to see if anything has gone wrong with our inputs.
if [[ $totalOtherBefore -ne $totalOtherAfter ]]; then

    echo "Error: The total number of non cbz or cbr files has changed. Before there were $totalOtherBefore files and after there are $totalOtherAfter files. Please see the logs to find the missing files. Exiting script."
    exit

fi

# Check that we have the right number of new files.

declare -a missingFiles=()
missingFlag=0

if [[ $conversionFormat == cbz ]]; then

    if [[ $totalCbzNewPlusErrors -ne $totalCbrBefore ]] || [[ $totalCbzNew -ne $totalArchivedCbr ]]; then

        echo "Error: The number of new cbz files does not match the number of archived cbr files or the number of cbz files plus error files does not match the number of cbr files before running the script. Before there were $totalCbrBefore cbr files and there are currently $totalCbzNewPlusErrors cbz plus error files. There are currently $totalArchivedCbr archived cbr files. Please see the logs to find the missing files. Exiting script."
        exit

    fi

    for file in $archiveDir/*/*.cbr; do

        dirname=$(basename "$(dirname "$file")")
        filename=$(basename "${file%.*}")

        if [ ! -e "$dirname/$filename.cbz" ]; then
            missingFiles+=("$dirname/$filename.cbz")
            missingFlag=1
        fi

    done

else

    if [[ $totalCbrNewPlusErrors -ne $totalCbzBefore ]] || [[ $totalCbrNew -ne $totalArchivedCbz ]]; then

        echo "The number of new cbr files does not match the number of archived cbz files or the number of cbr files plus error files does not match the number of cbz files before running the script. Before there were $totalCbzBefore cbr files and there are currently $totalCbrNewPlusErrors cbr plus error files. There are currently $totalArchivedCbz archived cbr files. Please see the logs to find the missing files. Exiting script."
        exit

    fi

    for file in $archiveDir/*/*.cbz; do

        dirname=$(basename "$(dirname "$file")")
        filename=$(basename "${file%.*}")

        if [ ! -e "$dirname/$filename.cbr" ]; then
            missingFiles+=("$dirname/$filename.cbr")
            missingFlag=1
        fi

    done


fi

#Convert elasped conversion time to HH:MM:SS
let "hours=SECONDS/3600"
let "minutes=(SECONDS%3600)/60"
let "seconds=(SECONDS%3600)%60"
elapsedTime=$(printf "%02d" $hours):$(printf "%02d" $minutes):$(printf "%02d" $seconds)

echo "File processing completed in $elapsedTime."


if [[ missingFlag -eq 1 ]]; then
    echo "The converted version of the following files were not found during conversion. The originals can be found in $archiveDir."
    for file in "${missingFiles[@]}"; do
        echo -e $file
    done  
else    
    echo "The original files have been archived in $archiveDir".
    echo "New files have been checked against the old to ensure nothing is missing."
    echo "Do you wish to delete the old files?"
    select yn in "Yes, delete old files" "No, keep old files"; do

        case $yn in
            'Yes, delete old files' ) 
                echo "You have chosen to delete the old files. Deleting files..."
                rm -r $archiveDir/*
                echo "Files deleted. Operation complete."
                exit
                ;;
            'No, keep old files' ) 
                echo "You chose to keep the files. Operation complete"
                exit
                ;;
        esac

    done
fi

