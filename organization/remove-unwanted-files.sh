#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
regexpFile="$SCRIPT_DIR/expression-list"

# Intro text

# clear
# echo "This script is intended to remove unwanted files from cbz and cbr files. These may include files left behind by the OS, informational text files, or tags/signature images left by the scanner." 
# echo
# echo "Regular expressions are used to match the files from a blacklist that is maintained in a file called 'expression-list'. This file may be edited to add or remove expressions as needed."
# echo
# echo "For each expression in the list, you will be prompted with some information on either the number of files that will be removed or given a list of affected files. This should help you decide if you want to run that particular expression."
# echo
# read -n 1 -s -r -p "Press any key to continue"

# clear
# echo "This entire process can take some time, depending on the size of your library. There are two parts to the process. The first portion is shorter and interactive. We search for matching files and provide you with information and a prompt to decide if you want to run each expression."
# echo
# echo "This is for informational purposes to allow you to decide if you want to remove files that match a particular expression. You can exit at any time during this portion of the process."
# echo
# echo "The second portion of the process will remove any matching files for the expressions you decided to run. This can be very time consuming and you no longer have to interact with the interface. You can walk away and let it finish the process."
# echo
# read -n 1 -s -r -p "Press any key to continue"
# 
# clear
# echo "As we have no control over how scanners name their files, expressions may match files you do not want to remove. Always be sure before choosing yes to each expression so you do not lose valuable data."
# echo
# read -n 1 -s -r -p "Press any key to continue"


declare -a expList=() # Array to hold the list of expressions that the user agrees to run
declare -a fileList=() # Cbr/cbz files that contain matches from in the expList

# Loop through expression-list
while IFS=, read -u 3 -r title expression output message; do
    
    declare -a tmpFileList=()

    if [[ "${output}" == "count" ]]; then #Present user with count of matching files.
        
        clear
        echo "Please be patient while we search files for instances of '$title'."
        # cbz=$(find . -path "*/*.cbz" | while read f; do zipinfo -1 "$f" 2> /dev/null; done | grep -Ei "$expression" | wc -l)
        # cbr=$(unrar lb '*/*.cbr' | grep -Ei "$expression" | wc -l)
        i=0

        for f in */*.cbz; do
            cbz=$(zipinfo -1 "$f" 2> /dev/null | grep -Ei "$expression" | sed 's/.*\///g' | sed ':a;N;$!ba;s/\n/, /g')
            if [[ $cbz ]]; then
                tmpFileList+=("$(basename "$f")")
                ((i++))
            fi
        done

        for f in */*.cbr; do
            cbr=$(unrar lb "$f" | grep -Ei "$expression" | sed 's/.*\///g'| sed ':a;N;$!ba;s/\n/, /g')
            if [[ $cbr ]]; then
                tmpFileList+=("$(basename "$f")")
                ((i++))
            fi
        done

    elif [[ $output == "list" ]]; then #Present user with list of matching files.
        
        clear
        echo "Please be patient while we search files for instances of '$title'."
        # cbz=$(find . -path "*/*.cbz" | while read f; do zipinfo -1 "$f" 2> /dev/null; done | grep -Ei "$expression")
        # cbr=$(unrar lb '*/*.cbr' | grep -Ei "$expression")
        i=0
        for f in */*.cbz; do
            cbz=$(zipinfo -1 "$f" 2> /dev/null | grep -Ei "$expression" | sed 's/.*\///g' | sed ':a;N;$!ba;s/\n/, /g')
            if [[ $cbz ]]; then
                ((i++))
                tmpFileList+=("$(basename "$f")")
                userlistCbz+="$(basename "$f"): $cbz\n"
            fi
        done

        for f in */*.cbr; do
            cbr=$(unrar lb "$f" | grep -Ei "$expression" | sed 's/.*\///g'| sed ':a;N;$!ba;s/\n/, /g')
            if [[ $cbr ]]; then
                tmpFileList+=("$(basename "$f")")
                ((i++))
                userlistCbr+="$(basename "$f"): $cbr\n"
            fi
        done

    else
        clear
        echo $output
        echo "There is a problem reading the expression-list file. Please check the file and correct any errors before running this script again."
        exit
    fi

    # for b in "${tmpFileList[@]}"; do
    #     echo "$b"
    # done

    userlist="$userlistCbr$userlistCbz"
    echo "Here is the list of '$title' files that will be removed and the cbz/cbr where they reside."
    echo -e $userlist | sort | sed '/^[[:space:]]*$/d' | more -n 20

    while :; do

        if [[ "${output}" == "count" ]]; then
            read -p "The delete '$title' expression matches $i files. $message Do you want to remove them? ([y]es, [n]o, e[x]it)" -rsn1
        elif [[ $output == "list" ]]; then
            read -p "The delete '$title' expression matches the above files. $message Do you want to remove them? ([y]es, [n]o, e[x]it)" -rsn1
        else
            echo "There was a problem running the script. Please restart."
            exit
        fi

        echo
        
            case $REPLY in
                [Yy] )
                    echo "Added to queue. Files that match '$title' will be removed from your cbr/cbz files."
                    expList+=( "${expression}" ) # Add expression to the list to be run.
                    fileList+=( "${tmpFileList[@]}" ) # Add list of cbr/cbz files
                    sleep 3
                    break
                    ;;
                [Nn] )
                    echo "Skipping. Files matching '$title' will not be removed from your cbr/cbz files."
                    sleep 3
                    break
                    ;;
                [Xx] )
                    echo "Exiting the script."
                    exit
                    ;;
                * )
                    echo "I didn't understand that. Please choose an option."
                    read -r -t 0.001
                    ;;
            esac

    done

done 3< <(sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$regexpFile")

if [[ ${fileList[@]} -eq 0 ]] || [[ ${expList[@]} -eq 0 ]]; then
    echo "You have have chosen to not remove any files. Exiting the script."
    exit
else
    echo "Please wait while we remove the chosen files from your cbr/cbz files. This may take some time."
fi

for cbFile in "${fileList[@]}"; do
   
    if grep -Eiq ".+\.cbz$" <<< "$cbFile"; then
        echo "CBZ: $cbFile"
    elif grep -Eiq ".+\.cbr" <<< "$cbFile"; then
        echo "CBR: $cbFile"
    else
        echo "The file, $cbFile, is neither a CBR or CBZ file. Skipping."
    fi

done

