# Make an AIP on Mac/Linux with Bash Scripts and FITS

# Purpose:  
Transform a batch of folders into Archival Information Packages (AIPS), including generating PREMIS metadata, using two bash scripts, free tools, and xslt stylesheets on a Mac or Linux operating system.

# Description:

These scripts perform the following tasks:

   1. Organize the AIP folders into objects and metadata subfolders.
   2. Run FITS to extract technical metadata.
   3. Create PREMIS XML files (called master.xml).
   4. Validate the PREMIS XML.
   5. Organize the FITS and PREMIS files.
   6. Bag the AIPs.
   7. Validate the bags.
   8. Tar and zip the AIPs.
   9. Generate a MD5 of the zipped AIPs.

# Usage: 

Put the contents of each AIP into its own folder, named with the convention aip-id_AIP Title. All the AIP folders should be in a single directory (the source directory).

Run the first script with the command aip-structure_script.sh source-directory
	Where source-directory is the full file path to the directory with your AIP folders.

Add additional files to the metadata folders.

Run the second script with the command aip-finish_script source-directory department
	Where source-directory is the full file path to the directory with your AIP folders.
	Where department is your department name.

# Dependencies:

   - bagit.py (https://github.com/LibraryOfCongress/bagit-python)
   - FITS (https://projects.iq.harvard.edu/fits/downloads)
   - md5sum (should come installed on a Mac/Linux machine)
   - saxon9he xslt processor (http://saxon.sourceforge.net/)
   - xmlint (should come installed on a Mac/Linux machine)


# Installation:

   1. Install the dependencies (listed above).
   2. Download the "aip-workflowdocs" folder with the scripts, stylesheets, and other files needed for the workflow from GitHub and save to your computer.
   3. Update the filepath variables in the aip-finish script (lines 25-27) to the location of the aip-workflowdocs folder, FITS, and Saxon on your computer.
   4. Update the base-uri in the stylesheets and DTD to the base for your identifiers:
	-fits-to-master_singlefile.xsl: in variable name="uri" (line 57)
	-fits-to-master_multifile.xsl: in variable name="uri" (line 53)
	-premis.xsd: in the restriction pattern for objectIdentifierType (line 42)
   5. Change permission on the scripts so they are executable.

# Known Issue:

When you run the aip-structure_script, it will give an error that objects cannot be copied into itself. This error can be ignored as we do not actually want objects to be copied into itself.

# Initial Author

Adriane Hanson, Head of Digital Stewardship, 2017.

# Acknowledgements

This workflow was developed and tested with the assistance of Brandon Pieczko (Processing and Digital Archivist, Russell Library) and Steve Armour (University Archives & Electronic Records Archivist, Hargrett Library).

The aip-finish script incorporates a script to tar and zip the files which was developed by Shawn Kiewel, UGA Libraries Application Analyst.
