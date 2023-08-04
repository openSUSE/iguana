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
            python3 partition.py $path
        else
            echo "incorrect file type"
        fi
    else
        echo "file does not exist"
    fi
else
    read -p "Please enter the URL: " URL
    curl --insecure -L -O -v $URL
    filename="$(ls | grep .json)"
    #echo "$filename"
    python3 partition.py "$filename"
fi

exit