<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
  <xsl:import
    href="http://docbook.sourceforge.net/release/xsl/current/xhtml/chunk.xsl"/>
  <xsl:param name="admon.graphics">1</xsl:param>
  <xsl:param name="navig.graphics">1</xsl:param>
  <xsl:param name="chunk.section.depth">0</xsl:param>
  <xsl:param name="draft.watermark.image">images/draft.png</xsl:param>
  <xsl:param name="html.stylesheet">maint-guide.css</xsl:param>
  <xsl:param name="section.autolabel">1</xsl:param>
  <xsl:param name="section.label.includes.component.label">1</xsl:param>
  <xsl:param name="use.id.as.filename">1</xsl:param>
<!-- We don't want title in HTML -->
<xsl:template name="generate.html.title"/>
</xsl:stylesheet>
