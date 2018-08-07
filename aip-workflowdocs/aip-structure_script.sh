#!/bin/bash

# Purpose: converts a batch of AIPs into required directory structure (objects and metadata subfolders)
# Script has one required argument: the path of the directory containing the AIP folders (source directory)

# Prior to running the script:
   # The contents for each AIP should be in a folder named 'aip-id_AIP Title'
   # All of the AIP folders should be in a single folder

VERSION=1.2
# change: updated terminology from proto-aip (local term we used to describe AIPs in the process of being made) to AIP (standard term)


# Check that have the required input in the terminal (1 argument, which is a valid directory path)
if [ "$#" -ne "1" ]
  then 
    echo "Error: Include the source directory as an argument to run this script"
    exit 1
fi

if [ ! -d "$1" ]
  then 
    echo "Error: Source directory is not a valid path"
    exit 1
fi

# In each AIP folder: make a subfolder called objects, move all files and folders into objects, and make a subfolder called metadata
# Known issue: it will give an error message that cannot move objects into itself - ignore the error

cd "$1"

for d in *; do
  mkdir "$d"/objects
  mv "$d"/* "$d"/objects
  mkdir "$d"/metadata
done

