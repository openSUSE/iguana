#!/bin/bash

echo "Welcome!"
echo "please choose the format you would like to enter the input file: "
echo "(1): Path to file"
echo "(2): URL to pull file from"
echo "(0): quit"

read -p "Enter selection: " selection

while [[ $selection != [012] ]]
do
    read -p "No such option of ($selection), please enter a valid selection:" selection
done

echo ""
if [[ $selection == '0' ]]
then
    echo "Thank you, goodbye"
    exit
elif [[ $selection == '1' ]]
then
    read -p "Please enter the path to the input file: " path
    test -f $path
    if [ $? == 0 ]
    then  
        echo "$path exists"
        if [[ $path == *.json ]]
        then
            echo "Partitioning according to $path"
            #python3 partition.py $path
        else
            echo "incorrect file type"
        fi
    else
        echo "file does not exist"
    fi
else
    # TODO: Figure out how to get the file name from the curl
    # command, and the run that file. Right now it assumes there
    # is only one JSON file in the local directory. Will break if
    # mulitple JSON files are in the same folder.
    read -p "Please enter the URL: " URL
    filename=$(mktemp -p .)
    curl --insecure -L -o $filename -v $URL
    echo "$filename"
    #python3 partition.py "$filename"
fi

exit