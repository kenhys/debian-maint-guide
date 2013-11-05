<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output
    method="xml" indent="yes" encoding="utf-8"
    doctype-system="http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd"
    doctype-public="-//OASIS//DTD DocBook XML V4.5//EN"/>


  <!-- filename was not compatible with # in URL -->
  <xsl:template match="ulink[.!='']">
    <xsl:copy-of select="."/>
    <xsl:if test="not(contains(@url,'wikipedia'))">
    (<ulink>
         <xsl:attribute name="url">
         <xsl:value-of select="@url"/>
         </xsl:attribute>
         <xsl:if test="starts-with(@url,'file:///')">
         <xsl:value-of select="substring-after(@url,'://')"/>
         </xsl:if>
         <xsl:if test="not(starts-with(@url,'file://'))">
         <xsl:value-of select="@url"/>
         </xsl:if>
    </ulink>)
    </xsl:if>
  </xsl:template>
  <xsl:template match="ulink[.='']">
    <ulink>
         <xsl:attribute name="url">
         <xsl:value-of select="@url"/>
         </xsl:attribute>
         <xsl:if test="starts-with(@url,'file:///')">
         <xsl:value-of select="substring-after(@url,'://')"/>
         </xsl:if>
         <xsl:if test="not(starts-with(@url,'file://'))">
         <xsl:value-of select="@url"/>
         </xsl:if>
    </ulink>
  </xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
