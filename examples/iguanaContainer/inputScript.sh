#!/bin/bash

# Checks if there is an inputted partitioning
# file or URL within the kernel cmdline
input=$(python3 kernelInput.py)
if [ -z "$input" ]
then
    echo empty
    # Not specified in kernel cmdline
    # Now check for environmental variable.
    # Which will be inputted as an argument
    input=$1
    if [ -z "$input" ]
    then
        # If no environmental variable is inputted
        # then we run the interactive script
        ./interactive.sh
        exit
    fi
fi

# Checks if the input is a valid URL
if curl -s $input
then
    # If the URL is valid, then run curl again
    # and store the contents in a file.
    # Then run the partitioning program using that
    # file as input.
    filename=$(mktemp -p .)
    curl --insecure -L -o $filename -v $input
    #python3 partition.py "$filename"
else
    # Otherwise if the curl was unsuccessful, in other
    # words the URL was invalid, then check to see if
    # the input is a file path instead
    if test -f $input
    then  
        # If the input is a file path, then check if
        # the file is a json file
        echo "$input exists"
        if [[ $input == *.json ]]
        then
            # If it is a json file, then partition
            # according to the json file
            echo "Partitioning according to $input"
            #python3 partition.py $input
        else
            echo "$input is a file but of incorrect file type"
        fi
    else
        echo "$input is not a valid URL and not a valid file"
    fi 
fi
echo $input