<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:premis="http://www.loc.gov/premis/v3"
	xmlns:dc="http://purl.org/dc/terms/"
	xpath-default-namespace="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
	<xsl:output method="xml" indent="yes" />
	 <xsl:strip-space elements="*" />
	
<!--Purpose: transform cleaned-up FITS output into the master.xml file when there is more than one file in the aip. For aips with one file, the fits-to-master_singlefile.xsl stylesheet is used.-->
<!--The master.xml file is mostly PREMIS, with 2 Dublin Core fields, and is used for importing metadata into the ARCHive (digital preservation storage). See the UGA Libraries AIP Definition for details.-->
<!--FITS output is run through the fits-cleanup.xsl stylesheet before it is run through this stylesheet-->
	
	
<!-- ........................................................................................................................................................................................................................................................................................................................-->
<!-- MASTER TEMPLATE-->
<!-- ........................................................................................................................................................................................................................................................................................................................-->
	
	<!--creates the overall structure of the master.xml file and inserts the values for aip title (from a variable) and literal values for rights (in copyright) and aip objectCategory (representation) since they rarely change-->
	<xsl:template match="/">
		<master>
			<dc:title><xsl:value-of select="$aip-title" /></dc:title>
			<dc:rights>http://rightsstatements.org/vocab/InC/1.0/</dc:rights>
			<aip>
				<premis:object>
					<xsl:call-template name="aip-object-id" />
					<xsl:call-template name="aip-version" />
					<premis:objectCategory>representation</premis:objectCategory>
					<premis:objectCharacteristics>
						<xsl:call-template name="aip-size" />
						<xsl:call-template name="aip-unique-formats-list" />
						<xsl:call-template name="aip-unique-creating-application-list" />
						<xsl:call-template name="aip-unique-inhibitors-list" />
					</premis:objectCharacteristics>
					<xsl:call-template name="relationship-collection" />
				</premis:object>
			</aip>
			<filelist>
				<xsl:apply-templates select="combined-fits/fits" />
			</filelist>
		</master>
	</xsl:template>
	
	
<!-- ........................................................................................................................................................................................................................................................................................................................-->
<!-- PARAMETER, VARIABLES, and REGEX-->
<!-- ........................................................................................................................................................................................................................................................................................................................-->
	
	<!--value for the department parameter is entered into the command line when starting the aip-finished script-->
	<!--to run this stylesheet without using the command line, delete the required="yes" attribute and put the value for the parameter inside the <xsl:param> tag-->
	<xsl:param name="dept" required="yes" />
		
	<!--$uri: the unique identifier for the group in the ARCHive (digital preservation system), which is used with all other identifiers-->
	<xsl:variable name="uri">insert-base-uri/<xsl:value-of select="$dept" /></xsl:variable>
	
	<!--$filepath: gets the filepath from the first instance of fits/fileinfo/filepath to use for calculating the other variables-->
	<xsl:variable name="filepath" select="(//fileinfo/filepath)[1]" />
	
	
	<!--the $collection-id, $aip-id, and $aip-title regex matches the pattern from the beginning of the path (with ^.+?) so only the first match is selected since the pattern can be in more than one place in the filepath-->
	
	<!--$collection-id: gets the collection-id from the first instance of fits/fileinfo/filepath with the department parameter indicating what pattern to match-->
	<xsl:variable name="collection-id">
		<!--Russell collection-id is formatted rbrl-###-->
		<xsl:if test="$dept='russell'">
			<xsl:analyze-string select="$filepath" regex="^.+?/(rbrl-\d{{3}})">
				<xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>	
		<!--Hargrett collection-id may be formatted harg-ms####, harg-ua####, or harg-ua##-####-->
		<xsl:if test="$dept='hargrett'">
			<xsl:analyze-string select="$filepath" regex="^.+?/(harg-[mu][sa]\d{{0,2}}-?\d{{4}})">
				<xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>
	</xsl:variable>
	
	
	<!--$aip-id: gets the aip-id from the first instance of fits/fileinfo/filepath with the department parameter indicating what pattern to match-->
	<xsl:variable name="aip-id">
		<!--Russell aip-id is formatted rbrl-###-er-######-->
		<xsl:if test="$dept='russell'">
			<xsl:analyze-string select="$filepath" regex="^.+?/(rbrl-\d{{3}}-er-\d{{6}})">
				<xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>
		<!--Hargrett aip-id may be formatted harg-ms####er####, harg-ua####er####, or harg-ua##-####er#### -->
		<xsl:if test="$dept='hargrett'">
			<xsl:analyze-string select="$filepath" regex="^.+?/(harg-[mu][sa]\d{{0,2}}-?\d{{4}}er\d{{4}})">
				<xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>
	</xsl:variable>
	
	
	<!--$aip title: gets the aip title from the first instance of fits/fileinfo/filepath with the department parameter indicating what pattern to match-->
	<xsl:variable name="aip-title">
		<!--Russell filepath is formatted A:/any/thing/aip-id_AIP Title/anything/else.ext-->
		<xsl:if test="$dept='russell'">
			<xsl:analyze-string select="$filepath" regex="^.+?/rbrl-\d{{3}}-er-\d{{6}}_(.*?)/">
				<xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>
		<!--Hargrett filepath is formatted A:/any/thing/aip-id_AIP Title/anything/else.ext-->
		<xsl:if test="$dept='hargrett'">
			<xsl:analyze-string select="$filepath" regex="^.+?/harg-[mu][sa]\d{{0,2}}-?\d{{4}}er\d{{4}}_(.*?)/">
				<xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>	
	</xsl:variable>
	
	
	<!--file-id: gets the file-id (relative file path, which is everything beginning with the aip-id) from each fits/fileinfo/filepath with the department parameter indicating what pattern to match-->
	<xsl:template name="get-file-id">
		<xsl:if test="$dept='russell'">
			<xsl:analyze-string select="fileinfo/filepath" regex="rbrl-\d{{3}}-er-\d{{6}}.*">
				<xsl:matching-substring><xsl:value-of select="." /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>
		<xsl:if test="$dept='hargrett'">
			<xsl:analyze-string select="fileinfo/filepath" regex="harg-[mu][sa]\d{{0,2}}-?\d{{4}}er\d{{4}}.*">
				<xsl:matching-substring><xsl:value-of select="." /></xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:if>
	</xsl:template>
	
	
<!-- ........................................................................................................................................................................................................................................................................................................................-->
<!-- AIP SECTION TEMPLATES -->
<!-- summary information about the AIP as a whole-->
<!-- ........................................................................................................................................................................................................................................................................................................................-->
	
	<!--aip-id: PREMIS 1.1 (required): inserts the value for the identifier type (group uri) and the aip-id from variables -->
	<xsl:template name="aip-object-id">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:value-of select="$uri" /></premis:objectIdentifierType>
			<premis:objectIdentifierValue><xsl:value-of select="$aip-id" /></premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	
	<!--aip version: PREMIS 1.1 (required): inserts the value for the identifier type (the aip uri, which combines the group uri and the aip-id) and a default value of 1 for the identifier value-->
	<!--update the identifier value for later versions of AIPs prior to running the script-->
	<xsl:template name="aip-version">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:value-of select="$uri" />/<xsl:value-of select="$aip-id" /></premis:objectIdentifierType>
			<premis:objectIdentifierValue>1</premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	
	<!--aip size: PREMIS 1.5.3 (optional): gets every file size from fits/fileinfo/size and adds the values to give the total size of the aip in bytes, formatted as a number with no decimal places-->
	<xsl:template name="aip-size">
		<premis:size><xsl:value-of select="format-number(sum(//fileinfo/size),'#')" /></premis:size>	
	</xsl:template>
	
	
	<!--aip format list: PREMIS 1.5.4 (required): gets a unique list of file formats in the aip based on file name, version, and PUID from fits/identification/identity-->
	<!--if different files are identified as the same format by different tools and not all the tools include a PUID, the format is in the list twice, once with the PUID and once without, to ensure complete information is captured-->
	<!--if a format has multiple possible PUIDs because it has multiple possible versions, all PUIDs are in the same premis:formatRegistryKey element for each version since we do not know which one is associated with which version-->
	<xsl:template name="aip-unique-formats-list">
		<xsl:for-each-group select="//identity" group-by="concat(@format,version,externalIdentifier[@type='puid'])">
			<xsl:sort select="current-grouping-key()" />
			<premis:format>
				<premis:formatDesignation>
					<premis:formatName><xsl:value-of select="@format" /></premis:formatName>
					<xsl:if test="version"><premis:formatVersion><xsl:value-of select="version" /></premis:formatVersion></xsl:if>
				</premis:formatDesignation>
				<xsl:if test="externalIdentifier[@type = 'puid']">
					<premis:formatRegistry>
						<premis:formatRegistryName>https://www.nationalarchives.gov.uk/PRONOM</premis:formatRegistryName>
						<premis:formatRegistryKey><xsl:value-of select="externalIdentifier[@type = 'puid']" /></premis:formatRegistryKey>
						<premis:formatRegistryRole>specification</premis:formatRegistryRole>
					</premis:formatRegistry>
				</xsl:if>					
				<!--tool is selected with an absolute path, rather than from the current group, because multiple files identified as the same format can be identified by different sets of tools and this captures the complete list of tools-->
				<xsl:for-each select="//identity/tool">
					<xsl:sort select="@toolname"/>
					<!--variable is used to match a tool to the right format name/version/PUID combination by generating the equivalent of the group-by value for the format a tool identified-->
					<xsl:variable name="group" select="concat(../@format,following-sibling::version,following-sibling::externalIdentifier[@type='puid'])"/>
					<!--variable is used to identify duplicate tools by combining the tool name with format name/version/PUID-->
					<xsl:variable name="dedup" select="concat(@toolname,$group)"/>
					<!--only include a format note for a tool if it identified a file as having this name/version/PUID combination AND a tool with the same tool name later in the xml has not identified the same name/version/PUID combination-->  
					<xsl:if test="$group=current-grouping-key() and not(following::tool[concat(@toolname,../@format,following-sibling::version,following-sibling::externalIdentifier[@type='puid'])=$dedup])">
						<premis:formatNote>Format identified by <xsl:value-of select="@toolname" /> version <xsl:value-of select="@toolversion" /></premis:formatNote>
					</xsl:if>	
				</xsl:for-each>								
				<!--if there is no tool element, creates an empty premis:formatNote element so the master.xml does not validate to alert staff to the problem because this information is required-->
				<xsl:if test="not(tool)"><premis:formatNote /></xsl:if>
			</premis:format>
		</xsl:for-each-group>	
	</xsl:template>	
	
	
	<!--aip creating application list: PREMIS 1.5.5 (optional): gets a unique list of creating applications in the aip based on application name and version from fits/fileinfo/creatingApplication-->
	<xsl:template name="aip-unique-creating-application-list">
		<xsl:for-each-group select="//fileinfo/creatingApplication" group-by="concat(creatingApplicationName,creatingApplicationVersion)">
			<xsl:sort select="current-grouping-key()" />
			<!--not all creatingApplication elements include a creatingApplicationName: information from those elements is included in the filelist section but not here-->
			<xsl:if test="creatingApplicationName">
				<premis:creatingApplication>
					<premis:creatingApplicationName><xsl:value-of select="creatingApplicationName" /></premis:creatingApplicationName>
					<xsl:if test="creatingApplicationVersion"><premis:creatingApplicationVersion><xsl:value-of select="creatingApplicationVersion" /></premis:creatingApplicationVersion></xsl:if>
				</premis:creatingApplication>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:template>
	
	
	<!--aip inhibitors list: PREMIS 1.5.6 (required if applicable): gets a unique list of inhibitors in the aip based on inhibitor type and inhibitor target from fits/fileinfo/inhibitor-->
	<xsl:template name="aip-unique-inhibitors-list">
		<xsl:for-each-group select="//fileinfo/inhibitor" group-by="concat(inhibitorType,inhibitorTarget)">
			<xsl:sort select="current-grouping-key()" />
			<!--not all inhibitor elements include a inhibitorType: information from those elements are not included in the master.xml because that is not valid PREMIS-->
			<xsl:if test="inhibitorType">
				<premis:inhibitors>
					<premis:inhibitorType><xsl:value-of select="inhibitorType" /></premis:inhibitorType>
					<xsl:if test="inhibitorTarget"><premis:inhibitorTarget><xsl:value-of select="inhibitorTarget" /></premis:inhibitorTarget></xsl:if>	
				</premis:inhibitors>
			</xsl:if>	
		</xsl:for-each-group>
	</xsl:template>
	
	
	<!--aip relationship to collection: PREMIS 1.13 (required if applicable): inserts the value for the identifier type (group uri) and collection-id from variables-->
	<xsl:template name="relationship-collection">
		<premis:relationship>
			<premis:relationshipType>structural</premis:relationshipType>
			<premis:relationshipSubType>Is Member Of</premis:relationshipSubType>
			<premis:relatedObjectIdentifier>
				<premis:relatedObjectIdentifierType><xsl:value-of select="$uri" /></premis:relatedObjectIdentifierType>
				<premis:relatedObjectIdentifierValue><xsl:value-of select="$collection-id" /></premis:relatedObjectIdentifierValue>
			</premis:relatedObjectIdentifier>
		</premis:relationship>
	</xsl:template>
	
	
	<!-- ........................................................................................................................................................................................................................................................................................................................-->
<!-- FILELIST SECTION TEMPLATES -->
<!-- Detailed information about each file in the aip. When tools generate conflicting information (i.e. multiple possible formats or multiple possible created dates) all possible information is kept in the master.xml since we do not currently have the time or expertise to determine which is the most accurate-->
	<!-- ........................................................................................................................................................................................................................................................................................................................-->
	
	<!--master template to make a premis:object for each file in the aip-->
	<xsl:template match="fits">
		<premis:object>
			<xsl:call-template name="file-id" />
			<premis:objectCategory>file</premis:objectCategory>
			<premis:objectCharacteristics>
				<xsl:apply-templates select="fileinfo/md5checksum" />
				<xsl:apply-templates select="fileinfo/size" />
				<xsl:apply-templates select="identification/identity" />
				<xsl:apply-templates select="fileinfo/creatingApplication[string()]" />
				<xsl:apply-templates select="fileinfo/inhibitor[inhibitorType]" />
			</premis:objectCharacteristics>
			<xsl:call-template name="relationship-aip" />
		</premis:object>
	</xsl:template>
	
	
	<!--file id: PREMIS 1.1 (required): inserts the value for the identifier type (the aip uri, which combines the group uri and the aip-id) from a variable and gets the file-id from the get-file-id template-->
	<xsl:template name="file-id">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:value-of select="$uri" />/<xsl:value-of select="$aip-id" /></premis:objectIdentifierType>
			<premis:objectIdentifierValue><xsl:call-template name="get-file-id" /></premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	

	<!--file MD5: PREMIS 1.5.2 (optional in master.xml): gets MD5 checksum from fits/fileinfo/md5checksum-->
	<xsl:template match="md5checksum">
		<xsl:variable name="md5" select="." />
		<premis:fixity>
			<premis:messageDigestAlgorithm>MD5</premis:messageDigestAlgorithm>
			<premis:messageDigest><xsl:value-of select="$md5" /></premis:messageDigest>
			<premis:messageDigestOriginator><xsl:value-of select="$md5/@toolname" /> version <xsl:value-of select="$md5/@toolversion"></xsl:value-of></premis:messageDigestOriginator>
		</premis:fixity>	
	</xsl:template>
	
	
	<!--file size: PREMIS 1.5.3 (optional): gets file size (in bytes) from fits/fileinfo/size-->
	<xsl:template match="size">
		<premis:size><xsl:value-of select="." /></premis:size>
	</xsl:template>
	
	
	<!--file format list: PREMIS 1.5.4 (required): gets file format information from fits/identification/identity (name, version, puid, tools that identified it) and fits/filestatus (if valid or well-formed)-->
	<!--if different tools get different results (multiple possible formats or multiple possible versions of a format), each format name/version variation is included as separate premis:format elements-->
	<xsl:template match="identity">
		<premis:format>
			<premis:formatDesignation>
				<premis:formatName><xsl:value-of select="@format" /></premis:formatName>
				<xsl:if test="version"><premis:formatVersion><xsl:value-of select="version" /></premis:formatVersion></xsl:if>
			</premis:formatDesignation>
			<xsl:if test="externalIdentifier[@type = 'puid']">
				<premis:formatRegistry>
					<premis:formatRegistryName>https://www.nationalarchives.gov.uk/PRONOM</premis:formatRegistryName>
					<premis:formatRegistryKey><xsl:value-of select="externalIdentifier[@type = 'puid']" /></premis:formatRegistryKey>
					<premis:formatRegistryRole>specification</premis:formatRegistryRole>
				</premis:formatRegistry>
			</xsl:if>
 			<!--if an externalIdentifier other than PUID is present, creates an empty premis:formatRegistry element so the master.xml does not validate to alert staff to research if the identifier should be included-->
			<xsl:if test="externalIdentifier[not(@type='puid')]"><premis:formatRegistry/></xsl:if>
			<!--applies templates for the three kinds of premis:formatNotes, each of which can occur multiple times: if it is valid, if it is well-formed, and the tool(s) that identified the format-->
			<!--for files with multiple possible formats, only includes a formatNote for valid and well-formed if the same tool that determined a format was valid or well-formed also identified that format--> 
			<xsl:variable name="tool" select="tool/@toolname"/>
			<xsl:apply-templates select="../following-sibling::filestatus/valid[@toolname=$tool]" />
 			<xsl:apply-templates select="../following-sibling::filestatus/well-formed[@toolname=$tool]" />
 			<xsl:apply-templates select="tool" />
 			<!--if there is no tool element, creates an empty premis:formatNote element so the master.xml does not validate to alert staff to the problem because this information is required-->
			<xsl:if test="not(tool)"><premis:formatNote /></xsl:if>
		</premis:format>
	</xsl:template>
	
	<xsl:template match="valid">
		<xsl:variable name="valid" select="." />
		<!--if the valid FITS element does not have the expected value (true or false) it produces an empty premis:formatName field so the master.xml does not validate and staff know to research-->
		<xsl:choose>
 			<xsl:when test="$valid='true'">
     				<premis:formatNote>Format identified as valid by <xsl:value-of select="$valid/@toolname" /> version <xsl:value-of select="$valid/@toolversion" /></premis:formatNote>
 			</xsl:when>
 			<xsl:when test="$valid='false'">
    		 		<premis:formatNote>Format identified as not valid by <xsl:value-of select="$valid/@toolname" /> version <xsl:value-of select="$valid/@toolversion" /></premis:formatNote>
 			</xsl:when>
 			<xsl:otherwise><premis:formatNote /></xsl:otherwise>	
 		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="well-formed">
		<xsl:variable name="well-formed" select="." />
		<!--if the well-formed FITS element does not have the expected value (true or false) it produces an empty premis:formatName field so the master.xml does not validate and staff know to research-->
		<xsl:choose>
			<xsl:when test="$well-formed='true'">
     				<premis:formatNote>Format identified as well-formed by <xsl:value-of select="$well-formed/@toolname" /> version <xsl:value-of select="$well-formed/@toolversion" /></premis:formatNote>
 			</xsl:when>
 			<xsl:when test="$well-formed='false'">
     				<premis:formatNote>Format identified as not well-formed by <xsl:value-of select="$well-formed/@toolname" /> version <xsl:value-of select="$well-formed/@toolversion" /></premis:formatNote>
			</xsl:when>
 			<xsl:otherwise><premis:formatNote /></xsl:otherwise>	
 		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tool">
 		<premis:formatNote>Format identified by <xsl:value-of select="@toolname" /> version <xsl:value-of select="@toolversion" /></premis:formatNote>
	</xsl:template>
	
	
	<!--file creating applications: PREMIS 1.5.5 (optional): gets creating application values from fits/fileinfo/creatingApplication (name, version, created date)-->
	<!--if different tools get different results, the results from each tool are included as separate premis:creatingApplication elements. This can result in duplicate dates where the conflict between tools was in the timestamp but the year-month-day are the same and that is all that master.xml includes-->
	<!--applies a template that reformats the date to YYYY-MM-DD-->
	<!--tests for if creatingApplication has children with [string()] because if all name, version, and created date elements made by a tool are empty, the fits-cleanup.xsl will make any empty creatingApplication element for that tool and no premis:creatingApplication element should be made-->
	<xsl:template match="creatingApplication[string()]">
		<premis:creatingApplication>
			<xsl:if test="creatingApplicationName"><premis:creatingApplicationName><xsl:value-of select="creatingApplicationName" /></premis:creatingApplicationName></xsl:if>	
			<xsl:if test="creatingApplicationVersion"><premis:creatingApplicationVersion><xsl:value-of select="creatingApplicationVersion" /></premis:creatingApplicationVersion></xsl:if>	
			<xsl:apply-templates select="created" />
		</premis:creatingApplication>			
	</xsl:template>	
	
	
	<!--file inhibitors: PREMIS 1.5.6 (required if applicable): gets inhibitors from fits/fileinfo/inhibitor when inhibitor contains inhibitorType (inhibitor without type is not valid PREMIS)-->
	<!--if different tools get different results, the results from each tool are included as separate premis:inhibitor elements-->
	<xsl:template match="inhibitor[inhibitorType]">
		<premis:inhibitors>
			<premis:inhibitorType><xsl:value-of select="inhibitorType" /></premis:inhibitorType>
			<xsl:if test="inhibitorTarget"><premis:inhibitorTarget><xsl:value-of select="inhibitorTarget" /></premis:inhibitorTarget></xsl:if>
		</premis:inhibitors>
	</xsl:template>				
	
	<!--inhibitorTarget is not displayed if there is no inhibitorType match-->
	<xsl:template match="inhibitorTarget" />
	
	
	<!--file relationship to aip: PREMIS 1.13 (required if applicable): inserts the value for the identifier type (group uri) and the aip-id from variables-->
	<xsl:template name="relationship-aip">
		<premis:relationship>
			<premis:relationshipType>structural</premis:relationshipType>
			<premis:relationshipSubType>Is Member Of</premis:relationshipSubType>
			<premis:relatedObjectIdentifier>
				<premis:relatedObjectIdentifierType><xsl:value-of select="$uri" /></premis:relatedObjectIdentifierType>
				<premis:relatedObjectIdentifierValue><xsl:value-of select="$aip-id" /></premis:relatedObjectIdentifierValue>
			</premis:relatedObjectIdentifier>
		</premis:relationship>
	</xsl:template>
	
	
	<!-- ........................................................................................................................................................................................................................................................................................................................-->
<!-- CREATED DATE REFORMATTING TEMPLATE-->	
	
<!-- FITS tools have a lot of variation in how the created date is formatted. This template tests for each known format and makes it the required YYYY-MM-DD, typically by using regular expressions-->
<!-- If a new date format is encountered, the "otherwise" option will create an invalid premis:dateCreatedByApplication element so that the master.xml causes a validation error and staff know to research-->
	<!-- ........................................................................................................................................................................................................................................................................................................................-->

	<xsl:template match="created">
		<xsl:variable name="apdate" select="." />
		<xsl:choose>
			
			<!--reformats dates with the pattern Year:Month:Day Time and Year-Month-Day Time where year is 4 digits, month and day are 2 digits, and the day is followed by a space -->
			<!--examples: 2018:01:02 01:02:33 and 2000-10-05 9:15 PM-->
			<xsl:when test="matches($apdate, '^\d{4}:\d{2}:\d{2} ') or matches($apdate, '^\d{4}-\d{2}-\d{2} ')">
				<xsl:choose>
    					<!--if value of created is 0000:00:00 00:00:00 in FITS, it will not create a premis:dateCreatedByApplication element-->
    					<xsl:when test="$apdate='0000:00:00 00:00:00'" />
     					<xsl:otherwise>
        					<premis:dateCreatedByApplication>
            						<!--substring-before selects the date information before the space and then : is replaced with - for the required punctuation-->
            						<xsl:variable name="dateString"><xsl:value-of select="substring-before($apdate,' ')" /></xsl:variable>
            						<xsl:value-of select="replace($dateString, ':', '-')" />
        					</premis:dateCreatedByApplication>
    					</xsl:otherwise>    
				</xsl:choose>
			</xsl:when>
				
			<!--reformats dates with the pattern (Day of Week) Month Day(,) (Time) Year where Month is spelled out or abbreviated with letters, day is one or two digits, the year is four digits, and content in parethensis may or may not be present-->
			<!--examples: May 5, 2004 and Monday, January 7, 2001 11:22:33 PM and Wed Mar 01 11:22:33 EST 2003 -->
			<xsl:when test="matches($apdate, '[a-zA-Z]+ \d{1,2},? [0-9:A-Z ]*\d{4}')">
				<premis:dateCreatedByApplication>
					<xsl:analyze-string select="$apdate" regex="([a-zA-Z]+) (\d{{1,2}}),? [0-9:A-Z ]*(\d{{4}})">
						<xsl:matching-substring>
							<!--gets the year: already formatted correctly-->
							<xsl:variable name="year"><xsl:value-of select="regex-group(3)" /></xsl:variable>
							<!--gets the month: converts from words to two-digit number. Match gets both abbreviations (e.g. Jan) and full month (e.g. January) by just matching the beginning of the word.-->
							<xsl:variable name="month">
								<xsl:if test="matches(regex-group(1), '^Jan')">01</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Feb')">02</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Mar')">03</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Apr')">04</xsl:if>
								<xsl:if test="regex-group(1)='May'">05</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Jun')">06</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Jul')">07</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Aug')">08</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Sep')">09</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Oct')">10</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Nov')">11</xsl:if>
								<xsl:if test="matches(regex-group(1), '^Dec')">12</xsl:if>
							</xsl:variable>
							<!--gets the day: adds leading zero if not already 2 digits by formatting as a 2 digit number-->
							<xsl:variable name="day"><xsl:value-of select="format-number(number(regex-group(2)),'00')" /></xsl:variable>
							<!--puts the components of the date in the correct order-->
							<xsl:value-of select="$year, $month, $day" separator="-" />
						</xsl:matching-substring>
					</xsl:analyze-string>
				</premis:dateCreatedByApplication>
			</xsl:when>
				
			<!--reformats dates with the pattern Month/Day/Year Time where month and day are 1 or 2 digit numbers, with or without a leading zero, and year is a 2 or 4 digit number-->
			<!--examples: 12/01/99 12:01 PM and 1/5/2011 1:11:55--> 
			<xsl:when test="matches($apdate, '\d{1,2}/\d{1,2}/\d{2,4}')">
				<premis:dateCreatedByApplication>
					<xsl:analyze-string select="$apdate" regex="(\d{{1,2}})/(\d{{1,2}})/(\d{{2,4}})">
						<xsl:matching-substring>
							<!--gets the year: leaves it as is if greater than 999 (since already 4 digits), puts a 20 before the number if it is less than 50 (since most like the 2000's), and puts a 19 before anything else (since most likely the 1900s')-->
							<xsl:variable name="year">
								<xsl:choose>
									<xsl:when test="number(regex-group(3)) &gt; 999"><xsl:value-of select="regex-group(3)" /></xsl:when>
									<xsl:when test="number(regex-group(3)) &lt; 50">20<xsl:value-of select="regex-group(3)" /></xsl:when>
									<xsl:otherwise>19<xsl:value-of select="regex-group(3)" /></xsl:otherwise>
								</xsl:choose>		
							</xsl:variable>
							<!--gets the month: adds leading zero if not already 2 digits by formatting as a 2 digit number-->
							<xsl:variable name="month"><xsl:value-of select="format-number(number(regex-group(1)),'00')" /></xsl:variable>
							<!--gets the day: adds leading zero if not already 2 digits by formatting as a 2 digit number-->
							<xsl:variable name="day"><xsl:value-of select="format-number(number(regex-group(2)),'00')" /></xsl:variable>
							<!--puts the components of the date in the correct order-->
							<xsl:value-of select="$year, $month, $day" separator="-" />
						</xsl:matching-substring>
					</xsl:analyze-string>
				</premis:dateCreatedByApplication>
			</xsl:when>
				
			<!--if value of created is 0 in FITS, it will not create a premis:dateCreatedByApplication element-->
			<xsl:when test="$apdate='0'" />
				
			<!--if a date format is not yet accommodated in the stylesheet, it produces a premis:dateCreatedByApplication element that will cause the master.xml to not validate so staff know to add the new format-->
			<xsl:otherwise>
				<premis:dateCreatedByApplication>New Date Format Identified: Update Stylesheet</premis:dateCreatedByApplication>
			</xsl:otherwise>
				
		</xsl:choose>
	</xsl:template>						

</xsl:stylesheet>
