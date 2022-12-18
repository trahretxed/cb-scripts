#! /bin/bash

totalCbrBefore=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
totalCbzBefore=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
totalOtherBefore=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" | wc -l)
totalSumBefore=$((totalCbrBefore+totalCbzBefore+totalOtherBefore))
totalFilesBefore=$(find . -maxdepth 2 -type f | wc -l)
totalFilesBeforeList=${find . -maxdepth 2 -type f}
echo "CBR Before: ${totalCbrBefore}"
echo "CBZ Before: ${totalCbzBefore}"
echo "Other Files Before: ${totalOtherBefore}"
if [[ $totalSumBefore -ne totalFilesBefore ]];
    then
    echo "Error: Checksum mismatch. Sum ${totalSumBefore} does not match files ${totalFilesBefore}"
    exit
fi
echo "Checksum ${totalSumBefore} matches total files ${totalFilesBefore}"
echo "writing log of all files before running script to all-files-before.log"
echo ${totalFilesBeforeList}>all-files-before.log
# for f in *.cb*; do
#     if unrar t "${f}";
#         then
#         mkdir -p complete
#         echo $0
#         unrar e "${f}" "${f%%.*}/"
#         if [[ $f == *.cbz ]];
#             then
#             mv "${f}" "${f%%.*}".cbr
#         fi
#     	zip -j -9 "${f%%.*}.cbz" "${f%%.*}"/*
#     	mv "${f%%.*}".cbr complete/
#     	rm -r "${f%%.*}/"
#     elif unzip -t "${f}";
#         then
#         mv "${f}" "${f%%.*}".cbz    	
#     else
#         mkdir -p error
#     	mv "${f}" error/
#     fi
# done
# rm -r "Obnoxio The Clown (1983)"
totalCbrAfter=$(find . -maxdepth 2 -type f -iname "*.cbr" | wc -l)
totalCbzAfter=$(find . -maxdepth 2 -type f -iname "*.cbz" | wc -l)
totalCbzNew=$((totalCbzAfter-TotalCbzBefore))
totalOtherAfter=$(find . -maxdepth 2 -type f -not -iname "*.cbr" -not -iname "*.cbz" | wc -l)
totalSumAfter=$((totalCbrBefore+totalCbzBefore+totalOtherBefore))
totalFilesAfter=$(find . -maxdepth 2 -type f | wc -l)
totalFilesAfterList=$(find . -maxdepth 2 -type f)
totalCbrComplete=$(find . -maxdepth 2 -type f -path "complete/*.cbr" | wc -l)
totalCbrCompleteList=$(find . -maxdepth 2 -type f -path "complete/*.cbr")
totalFileErrors=$(find . -maxdepth 2 -type f -path "error/*")
totalFileErrorsList=$(find . -maxdepth 2 -type f -path "error/*")
echo "CBR Before: ${totalCbrBefore}"
echo "CBR After: ${totalCbrAfter}"
echo "CBZ Before: ${totalCbzBefore}"
echo "CBZ After: ${totalCbzAfter}"
echo "Other Files Before: ${totalOtherBefore}"
echo "Other Files After: ${totalOtherAfter}"
echo "Writing log of ${totalCbrComplete} archived CBR files to cbr-complete.log"
echo ${totalCbrCompleteList}>cbr-complete.log
echo "Writing log of ${totalFileErrors} archived error files to errors.log"
echo ${totalFileErrorsList}>errors.log
echo "Checksum ${totalSumBefore} matched total files ${totalFilesBefore} before running"
if [[ $totalSumAfter -ne totalFilesAFter ]];
    then
    echo "Error: Checksum mismatch. Sum ${totalSumAfter} does not match files ${totalFilesAfter}"
else
    echo "Checksum ${totalSumAfter} matches total files ${totalFilesAfter} after running"   
fi
if [[ $totalCbrComplete -ne totalCbzNew ]] || [[ $totalFilesBefore -ne $totalFilesAfter ]]
    then
    echo "The total number of new CBZ files ${totalCbzNew} does not equal the total number of archived CBR files ${totalCbrComplete} or the total number of files before ${totalFilesBefore} does not equal the total number of files after ${totalFilesAfter}"
    echo "Please check the logs for more details"
    exit
else
    echo "The total number of new CBZ files ${totalCbzNew} equals the total number of archived CBR files ${totalCbrComplete} and the total number of files before ${totalFilesBefore} equals the total number of files after ${totalFilesAfter}"
fi
exit
