#!/bin/bash

# Checks if there is an inputted partitioning
# file or URL within the kernel cmdline

# This line doesn't work for some reason
eval $(python3 kernelInput.py)

# PARTITIONING=$(python3 kernelInput.py)
if [ -z "$PARTITIONING" ]
then
    # Not specified in kernel cmdline
    # Now check for environmental variable.
    # Which will be inputted as an argument
    PARTITIONING=$PARTITIONING_URL
    if [ -z "$PARTITIONING" ]
    then
        # If no environmental variable is inputted
        # then we run the interactive script
        chmod 777 interactive.sh
        ./interactive.sh
        exit
    fi
fi

filename=$(mktemp -p .)
curl --insecure -L -o $filename -v $PARTITIONING
# Checks if the curl created a non empty file
if [ -s $filename ]
then
    # If the URL is valid and a file was created
    # run the partitioning program using that file as input.
    python3 partition.py "$filename"
else
    rm "$filename"
    # Otherwise if the curl was unsuccessful, in other
    # words the URL was invalid, then check to see if
    # the input is a file path instead
    if test -f $PARTITIONING
    then  
        # If the input is a file path, then check if
        # the file is a json file
        echo "$PARTITIONING exists"
        if [[ $PARTITIONING == *.json ]]
        then
            # If it is a json file, then partition
            # according to the json file
            echo "Partitioning according to $PARTITIONING"
            python3 partition.py "$PARTITIONING"
        else
            echo "$PARTITIONING is a file but of incorrect file type"
        fi
    else
        echo "$PARTITIONING is not a valid URL and not a valid file"
    fi 
fi
