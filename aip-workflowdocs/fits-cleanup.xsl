<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xpath-default-namespace="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
	<xsl:output method="xml" indent="yes" />
	<xsl:strip-space elements="*" />
	
<!-- Purpose: clean up FITS output to make it simpler to convert to the master.xml file using fits-to-master_singlefile.xsl or fits-to-master_multifile.xsl stylesheets-->
<!-- Removes empty elements and sections that are not used, makes the order of children consistent, creates one FITS identity section for each version of a format, and adds structure to the creating application and inhibitor information-->

<!--Throughout copy elements without their namespaces so it does not list all document namespaces as attributes of each element. In the resulting document, all are still within the FITS namespace-->
	
	<!-- copies everything unless there are more specific instructions in another template: maintains the overall document structure-->
	<xsl:template match="node()|@*">
		<xsl:copy><xsl:apply-templates select="node()|@*" /></xsl:copy>
	</xsl:template>
	
	<!--creates identity element and makes the order of the children elements consistent-->
	<!--if there are versions, makes one identity element per version-->
	<!--if none of the identity elements have an @format value, it will result in an empty identification element in the stylesheet output-->
	<xsl:template match="identification/identity">
		<!--will not make an identity element if the format does not have a name (the format attribute is blank)-->
		<xsl:if test="@format !=''">
			<xsl:choose>
				<!--reorganizes the identity element so there is one per version, as long as at least one version element has a value-->
				<xsl:when test="version[string()]">
					<xsl:apply-templates select="version[string()]" />
				</xsl:when>
				<xsl:otherwise>
					<identity format="{@format}" xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
						<!--only copies if the toolname attribute is not empty-->
						<xsl:copy-of select="tool[not(@toolname='')]" copy-namespaces="no" />
						<!--copies the value of all PUIDs into a single externalIdentifier element, but does not copy if the PUID has no value-->
						<xsl:if test="externalIdentifier[@type='puid'][string()]">
							<externalIdentifier type="puid"><xsl:value-of select="externalIdentifier[@type='puid'][string()]" /></externalIdentifier>
						</xsl:if>
						<!--copies each externalIdentifier element that has a value but is not a PUID so identifiers other than PRONOM can be detected-->
						<xsl:if test="externalIdentifier[not(@type='puid')][string()]">
							<xsl:copy-of select="externalIdentifier[not(@type='puid')][string()]" />
						</xsl:if>
					</identity>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>	
	</xsl:template>

	<!--Makes one identity element per version and copies all other format information into each of those identity elements-->
	<xsl:template match="version[string()]">
		<identity format="{../@format}" xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
			<!--only copies if the toolname attribute is not empty-->
			<xsl:copy-of select="../tool[not(@toolname='')]" copy-namespaces="no" />
			<!--copies the version-->
			<xsl:copy-of select="." copy-namespaces="no" />
			<!--copies the value of all PUIDs into a single externalIdentifier element, but does not copy if the PUID has no value-->
			<xsl:if test="../externalIdentifier[@type='puid'][string()]">
				<externalIdentifier type="puid"><xsl:value-of select="../externalIdentifier[@type='puid'][string()]" /></externalIdentifier>
			</xsl:if>
			<!--copies each externalIdentifier element that has a value but is not a PUID so identifiers other than PRONOM can be detected-->
			<xsl:if test="externalIdentifier[not(@type='puid')][string()]">
				<xsl:copy-of select="externalIdentifier[not(@type='puid')][string()]" />
			</xsl:if>
		</identity>
	</xsl:template>

	<!--adds structure to fileinfo element and makes the order of the child elements consistent-->
	<!--new elements creatingApplication and inhibitor are given the FITS namespace to simplify XPaths in the fits-to-master.xml stylesheets. While not correct, this is a temporary document so we decided it was acceptable to have the inaccuracy.-->
	<xsl:template match="fileinfo">
		<fileinfo xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
			<xsl:apply-templates select="filepath" />
			<xsl:apply-templates select="size" />
			<xsl:apply-templates select="md5checksum" />
			<!--make a new element, creatingApplication, for each tool that identified some creating application information. Children of creatingApplication are any created, creatingApplicationName, and creatingApplicationVersion elements identified by that tool, listed in that order, if they have a value-->
			<!--if none of the children identified by a tool have a value, it will result in an empty creatingApplication element in the stylesheet output-->
			<xsl:for-each-group select="created | creatingApplicationName | creatingApplicationVersion" group-by="@toolname">
				<creatingApplication tool="{@toolname}" xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
					<xsl:for-each select="current-group()">
						<xsl:sort select="name()" />
						<!--only copies if the created, creatingApplicationName, and/or creatingApplicationVersion element has a value-->
						<xsl:if test=".[string()]"><xsl:copy-of select="." copy-namespaces="no" /></xsl:if>
					</xsl:for-each>
				</creatingApplication>
			</xsl:for-each-group>
			<!--make a new element, inhibitor, for each tool that identified some inhibitor information. Children of inhibitor are any inhibitorType and inhibitorTarget elements identified by that tool, listed in that order, if they have a value-->
			<!--if none of the children identified by a tool have a value, it will result in an empty creatingApplication element in the stylesheet output-->
			<xsl:for-each-group select="inhibitorType | inhibitorTarget" group-by="@toolname">
				<inhibitor tool="{@toolname}" xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
					<xsl:for-each select="current-group()">
						<xsl:sort select="name()" order="descending" />
						<!--only copies if the inhibitorType and/or inhibitorTarget element has a value-->
						<xsl:if test=".[string()]"><xsl:copy-of select="." copy-namespaces="no" /></xsl:if>
					</xsl:for-each>
				</inhibitor>
			</xsl:for-each-group>
		</fileinfo>
	</xsl:template>
	
	<!--only copy the filestatus element if it contains valid and/or well-formed elements that have a value and makes the order of child elements consistent-->
	<xsl:template match="filestatus">
		<xsl:if test="valid[string()] or well-formed[string()]">
			<filestatus xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output">
				<xsl:apply-templates select="valid" />
				<xsl:apply-templates select="well-formed" />
			</filestatus>
		</xsl:if>
	</xsl:template>
	
	<!--do not copy these elements or their children-->
	<xsl:template match="metadata | statistics" />
	
	<!--only copy these elements when apply-templates if they have a value-->
	<!--note: the same code is repeated in other parts of this stylesheet where the element is copied in the context of other code and so applying this template didn't work correctly there.-->
	<xsl:template match="version | filepath | size | md5checksum | valid | well-formed">
		<xsl:if test=".[string()]"><xsl:copy-of select="." copy-namespaces="no" /></xsl:if>
	</xsl:template>
	
</xsl:stylesheet>
