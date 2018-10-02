#!/bin/bash

# Purpose: finishes making a batch of AIPs once they are in the required directory structure
   # Runs FITS to extract metadata
   # Creates master.xml metadata files
   # Validates master.xml and only proceeds with rest of script on AIPs with valid master.xml
   # Organizes metadata files
   # Bags each AIP, validates the bag, and only proceed with rest of the script on AIPs that are valid
   # Tars and zips each AIP

# Requires bagit.py, FITS, md5sum, saxon9he xslt processor, xmllint, prepare_bag script, master.xml dtds, and fits stylesheets
# Script has two required arguments: the path of the directory containing the AIP folders (source directory) and the department name (hargrett or russell)

# Prior to running the script:
   # Copy files using rsync to exclude temporary files like .DS_Store and Thumbs.db which cause problems for bag validation
   # Run the aip-structure script to get the AIP folders into the right structure
   # Add optional metadata files to the metadata subfolders
   # If this is the first time using these scripts on this computer, update the filepath variables

VERSION=2.2
# previous changes: updated terminology from proto-aip (local term we used to describe AIPs in the process of being made) to AIP (standard term) and replaced absolute filepaths with variables to make it easier to run the script on other machines.
# changes: revised the command used to move FITS xml files to metdata folder, in order to account for maximum argument limit (ARG_MAX = 2097152 bytes)
#Filepath variables: give the absolute filepath for FITs, Saxon, and the scripts, stylesheets, etc. (workflowdocs).

fits='insert-filepath'
saxon='insert-filepath'
workflowdocs='insert-filepath'

# Check that have the required input in the terminal (2 arguments, the first of which is a valid directory path and the second is hargrett or russell)
if [ "$#" -ne "2" ]
  then echo "Error: Include the source directory and the department name as arguments to run this script"
  exit 1
fi

if [ ! -d "$1" ]
  then echo "Error: Source directory is not a valid path"
  exit 1
fi

if [ "$2" != "hargrett" ] && [ "$2" != "russell" ]
  then echo "Department name should be hargrett or russell"
  exit 1
fi

# Run FITS on each AIP's objects folder, save the FITS XML to a new folder in the AIP folder called fits-output, and rename the AIP folders to to remove the aip-name, leaving just the aip-id
echo ""
echo "Generating FITS XML"
echo ""

  cd "$fits"  # FITS needs to run from its home directory

  for d in "$1"/*; do
    mkdir "$d"/fits-output
    fits-1.2.0/fits.sh -r -i "$d"/objects -o "$d"/fits-output
    mv "$d" "${d//_*/}"
  done

  cd "$1"

# Generate master.xml file from FITS XML using stylesheets in 3 steps:
echo ""
echo "Generating master.xml files"
echo ""

  #1. Combine the FITS XML for each file of a AIP (located in the fits-output folder) into one valid XML file named aip-id_combined-fits.xml.
  for d in *; do
    #cat (concatenate) combines files into a single file and egrep removes the XML declarations since each document had one and valid XML cannot have repeated XML declarations.
    cat "$d"/fits-output/*.fits.xml | egrep -v "xml version" > "$d"/body.xml
    #makes valid XML by adding back a single XML declaration and adding opening and closing wrapper tags from existing documents open.xml and close.xml
    cat "$workflowdocs"/open.xml "$d"/body.xml "$workflowdocs"/close.xml > "$d"/${d}_combined-fits.xml
    rm "$d"/body.xml
  done

  #2. Make combined-fits files easier to work with by transforming the XML with saxon9he using the fits-cleanup.xsl stylesheet and saving result as aip-id_cleaned-fits.xml
  for i in */*_combined-fits.xml
    do java -cp "$saxon"/saxon9he.jar net.sf.saxon.Transform -s:"$i" -xsl:"$workflowdocs"/fits-cleanup.xsl -o:${i%_combined-fits.xml}_cleaned-fits.xml
  done

  #3. Make master.xml files by transforming the cleaned-fits.xml files with saxon9he using the appropriate fits-to-master.xsl stylesheet depending on if the AIP contains 1 file or multiple files
  for d in *; do
    #tests if there is a single file: find "$d"/objects -type f finds all the files in each AIP's object folder and wc -l counts how many were found
    if [ $(find "$d"/objects -type f | wc -l) = 1 ]
      then
	for i in "$d"/*_cleaned-fits.xml
	  # dept="$2" is giving the stylesheet parameter dept the value of the second argument from running the script, which is hargrett or russell
	  do java -cp "$saxon"/saxon9he.jar net.sf.saxon.Transform -s:"$i" -xsl:"$workflowdocs"/fits-to-master_singlefile.xsl -o:${i%_cleaned-fits.xml}_master.xml dept="$2"
        done
      else
	for i in "$d"/*_cleaned-fits.xml
	  do java -cp "$saxon"/saxon9he.jar net.sf.saxon.Transform -s:"$i" -xsl:"$workflowdocs"/fits-to-master_multifile.xsl -o:${i%_cleaned-fits.xml}_master.xml dept="$2"
	done
    fi
  done

# Validate master.xml file. If not valid, move the AIP folder to a new folder in the source directory called master-invalid.
# The rest of the script is not run on AIPs with invalid master.xml files, saving the time of bagging, tarring, and zipping.
echo ""
echo "Validating master.xml files"
echo ""

  mkdir master-invalid

  for d in *; do
    # 2>&1 means the variable stores the value of xmllint's error output and the text it would have displayed in the terminal
    valid=$(( xmllint --noout -schema "$workflowdocs"/master.xsd "$d"/*_master.xml ) 2>&1)
    if [[ "$d" = "harg"* ]] || [[ "$d" = "rbrl"* ]]
      then
        # One of these strings will be included in the tool output if there is a problem that staff need to investigate
        if [[ "$valid" == *"failed to load"* ]] || [[ "$valid" == *"fails to validate" ]]
	  then mv "$d" master-invalid
	fi
    fi
   done

# Organize metadata files: move some to metadata folder, copy some to additional folders for staff review (so not just in zip file), and delete temporary files
echo ""
echo "Organizing metadata"
echo ""

   mkdir master-xml
   mkdir aip-fits-xml

   # Rename all FITS xml for individual files to match naming conventions for metadata files
   for i in */fits-output/*.fits.xml
     do mv "$i" "${i//.fits/_fits}"
   done

   for d in *; do
     if [[ "$d" = "harg"* ]] || [[ "$d" = "rbrl"* ]]
       then
	     cp "$d"/*master.xml 'master-xml'
	     mv "$d"/*master.xml "$d"/metadata
	     mv "$d"/*_combined-fits.xml 'aip-fits-xml'
       # Using "find + mv" command here instead to just "mv" to account for the possiblity that the number of arguments (based on total size of files to be moved) could exceed the maxmimum number of allowed for the process
       find "$d"/fits-output -type f -exec mv -t "$d"/metadata {} +
	     rmdir "$d"/fits-output
	     rm "$d"/*_cleaned-fits.xml
     fi
   done

# Bag the AIPs, add _bag to the end of the folder name, and validate the bags
# Invalid bags are moved to a new folder bag-not-valid in the source directory and will not be tar/zipped.
echo ""
echo "Bagging AIPs"
echo ""

  for d in *; do
    if [[ "$d" = "harg"* ]] || [[ "$d" = "rbrl"* ]]
      then
	    bagit.py --md5 --sha256 --quiet "$d"
	    mv "$d" "${d}_bag"
    fi
  done

echo ""
echo "Validating the bags"
echo ""

  mkdir bag-not-valid

  for d in *; do
    # 2>&1 means the variable stores the value of bagit's error output and the text it would have displayed in the terminal
    valid=$(( bagit.py --validate "$d" ) 2>&1)
    if [[ "$d" = "harg"* ]] || [[ "$d" = "rbrl"* ]]
      then
        if [[ "$valid" = *"_bag is invalid"* ]]
          then
            mv "$d" bag-not-valid
        fi
    fi
  done

# Tar and zip the AIPs using the prepare_bag script and save to new folder in the source directory called aips-to-ingest
# As part of the script, the bags are renamed to include the uncompressed file size
echo ""
echo "Packaging AIPs (tar and zip)"
echo ""

  mkdir aips-to-ingest

  for d in *; do
    if [[ "$d" = "harg"* ]] || [[ "$d" = "rbrl"* ]]
      then
        "$workflowdocs"/prepare_bag "$d" 'aips-to-ingest'
    fi
  done


# Make MD5 manifest of packaged AIPs for ingest into ARCHive
echo ""
echo "Making MD5 manifest"
echo ""

  cd aips-to-ingest
  md5sum * > manifest.txt

echo ""
echo "Script is complete!"
echo ""
