<xsl:stylesheet version="1.0"
                 xmlns:marc="http://www.loc.gov/MARC21/slim"
                 xmlns:exsl="http://exslt.org/common"
                 xmlns:date="http://exslt.org/dates-and-times"
                 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                 extension-element-prefixes="exsl date"
                 exclude-result-prefixes="xsl">

  <xsl:output encoding="UTF-8" method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:variable name="vCurrentVersion">DLC mta2mbh v1.0.0-SNAPSHOT</xsl:variable>

  <!-- stylesheet parameters -->

  <!-- static datestamp for conversion, no default -->
  <xsl:param name="pConversionDatestamp"/>
  <!-- agency performing conversion, default to "DLC" -->
  <xsl:param name="pConversionAgency">DLC</xsl:param>
  <!-- URL for conversion program, default to lcnetdev version -->
  <xsl:param name="pConversionUri">https://github.com/lcnetdev/mta2mbh</xsl:param>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="marc:collection">
    <marc:collection>
      <xsl:apply-templates/>
    </marc:collection>
  </xsl:template>

  <xsl:template match="marc:record">
    <xsl:choose>
      <xsl:when test="substring(marc:leader,7,1)='z' and
                      (marc:datafield[@tag='100' or @tag='110' or @tag='111']/marc:subfield[@code='t'] or
                      marc:datafield[@tag='130'])">
        <xsl:variable name="vConversionDatestamp">
          <xsl:choose>
            <xsl:when test="$pConversionDatestamp != ''"><xsl:value-of select="$pConversionDatestamp"/></xsl:when>
            <xsl:when test="function-available('date:date-time')">
              <xsl:value-of select="concat(translate(substring(date:date-time(),1,19),'-:T',''),'.0')"/>
            </xsl:when>
            <xsl:when test="function-available('current-dateTime')">
              <xsl:value-of select="concat(translate(substring(current-dateTime(),1,19),'-:T',''),'.0')"/>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vMarcFields">
          <!-- generated 008 -->
          <xsl:variable name="vDateOnFile">
            <xsl:choose>
              <xsl:when test="marc:controlfield[@tag='008']">
                <xsl:value-of select="substring(marc:controlfield[@tag='008'],1,6)"/>
              </xsl:when>
              <xsl:when test="$vConversionDatestamp != ''">
                <xsl:value-of select="substring($vConversionDatestamp,1,6)"/>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="'      '"/></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="vModified">
            <xsl:choose>
              <xsl:when test="marc:controlfield[@tag='008']">
                <xsl:value-of select="substring(marc:controlfield[@tag='008'],39,1)"/>
              </xsl:when>
              <xsl:otherwise>|</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="vSource">
            <xsl:choose>
              <xsl:when test="marc:controlfield[@tag='008']">
                <xsl:value-of select="substring(marc:controlfield[@tag='008'],40,1)"/>
              </xsl:when>
              <xsl:otherwise>|</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <marc:controlfield>
            <xsl:attribute name="tag">008</xsl:attribute>
            <xsl:value-of select="concat($vDateOnFile,'|        ||||||||||||||||||||   ',$vModified,$vSource)"/>
          </marc:controlfield>

          <!-- push MARC fields for conversion -->
          <xsl:apply-templates select="marc:controlfield|marc:datafield"/>
          
          <!-- generated 884 -->
          <marc:datafield tag="884" ind1=" " ind2=" ">
            <marc:subfield code="a"><xsl:value-of select="$vCurrentVersion"/></marc:subfield>
            <xsl:if test="$vConversionDatestamp != ''">
              <marc:subfield code="g"><xsl:value-of select="$vConversionDatestamp"/></marc:subfield>
            </xsl:if>
            <xsl:if test="marc:controlfield[@tag='001']">
              <marc:subfield code="k"><xsl:value-of select="marc:controlfield[@tag='001']"/></marc:subfield>
            </xsl:if>
            <marc:subfield code="q"><xsl:value-of select="$pConversionAgency"/></marc:subfield>
            <marc:subfield code="u"><xsl:value-of select="$pConversionUri"/></marc:subfield>
          </marc:datafield>
        </xsl:variable>
        <marc:record>
          <xsl:for-each select="marc:leader">
            <xsl:variable name="vLdr5">
              <xsl:choose>
                <xsl:when test="substring(.,6,1)='o'">c</xsl:when>
                <xsl:when test="substring(.,6,1)='s'">c</xsl:when>
                <xsl:when test="substring(.,6,1)='x'">c</xsl:when>
                <xsl:otherwise><xsl:value-of select="substring(.,6,1)"/></xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="vLdr17">
              <xsl:choose>
                <xsl:when test="substring(.,18,1)='n'"><xsl:value-of select="' '"/></xsl:when>
                <xsl:otherwise>7</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <marc:leader><xsl:value-of select="concat('     ',$vLdr5,'qu a',substring(.,11,2),'     ',$vLdr17,'u 4500')"/></marc:leader>
          </xsl:for-each>
          <xsl:choose>
            <xsl:when test="function-available('exsl:node-set')">
              <xsl:for-each select="exsl:node-set($vMarcFields)/*">
                <xsl:sort select="@tag"/>
                <xsl:apply-templates mode="copy" select="."/>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="$vMarcFields"/>
            </xsl:otherwise>
          </xsl:choose>
        </marc:record>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>WARNING: Record </xsl:text><xsl:value-of select="position()"/>
          <xsl:if test="marc:controlfield[@tag='001']">
            <xsl:text> (</xsl:text><xsl:value-of select="marc:controlfield[@tag='001']"/><xsl:text>)</xsl:text>
          </xsl:if>
          <xsl:text> is not a title authority.</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- fields that require conversion -->
  <xsl:template match="marc:controlfield[@tag='008']">
    <xsl:if test="substring(.,8,1) = 'c' or substring(.,8,1) = 'n'">
      <marc:datafield>
        <xsl:attribute name="tag">884</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield>
          <xsl:attribute name="code">a</xsl:attribute>
          <xsl:choose>
            <xsl:when test="substring(.,8,1) = 'c'">Pinyin flipped</xsl:when>
            <xsl:otherwise>Pinyin not flipped</xsl:otherwise>
          </xsl:choose>
        </marc:subfield>
      </marc:datafield>
    </xsl:if>
    <xsl:if test="contains('abcd',substring(.,11,1)) and not(../marc:datafield[@tag='040'])">
      <marc:datafield>
        <xsl:attribute name="tag">040</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield>
          <xsl:attribute name="code">e</xsl:attribute>
          <xsl:call-template name="p040e">
            <xsl:with-param name="p008-10" select="substring(.,11,1)"/>
          </xsl:call-template>
        </marc:subfield>
      </marc:datafield>
    </xsl:if>
    <xsl:if test="contains('abc',substring(.,13,1))">
      <marc:datafield>
        <xsl:attribute name="tag">460</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield>
          <xsl:attribute name="code">b</xsl:attribute>
          <xsl:value-of select="substring(.,13,1)"/>
        </marc:subfield>
      </marc:datafield>
    </xsl:if>
    <xsl:if test="contains('abc',substring(.,14,1))">
      <marc:datafield>
        <xsl:attribute name="tag">461</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield>
          <xsl:attribute name="code">b</xsl:attribute>
          <xsl:value-of select="substring(.,14,1)"/>
        </marc:subfield>
      </marc:datafield>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield[@tag='040']">
    <marc:datafield>
      <xsl:attribute name="tag">040</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
      <xsl:if test="contains('abcd',substring(../marc:controlfield[@tag='008'],11,1)) and not(marc:subfield[@code='e'])">
        <marc:subfield>
          <xsl:attribute name="code">e</xsl:attribute>
          <xsl:call-template name="p040e">
            <xsl:with-param name="p008-10" select="substring(../marc:controlfield[@tag='008'],11,1)"/>
          </xsl:call-template>
        </marc:subfield>
      </xsl:if>
    </marc:datafield>
  </xsl:template>

  <xsl:template match="marc:datafield[@tag='046']">
    <marc:datafield>
      <xsl:attribute name="tag">046</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[contains('klopuv2',@code)]"/>
    </marc:datafield>
  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='100']">
    <xsl:variable name="agentSubfields">
      <xsl:apply-templates mode="copy" select="marc:subfield[contains('abcdejqg',@code)][following-sibling::marc:subfield[@code='t']]"/>
    </xsl:variable>
    <marc:datafield>
      <xsl:attribute name="tag">100</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:copy-of select="$agentSubfields"/>
    </marc:datafield>
    <marc:datafield>
      <xsl:attribute name="tag">240</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:attribute name="ind2">0</xsl:attribute>
      <marc:subfield>
        <xsl:attribute name="code">a</xsl:attribute>
        <xsl:value-of select="marc:subfield[@code='t']"/>
      </marc:subfield>
      <xsl:apply-templates mode="copy" select="marc:subfield[contains('fhklmoprsdgn',@code)][preceding-sibling::marc:subfield[@code='t']]"/>
    </marc:datafield>
    
    <xsl:if test="marc:subfield[@code='l']">
      <marc:datafield>
        <xsl:attribute name="tag">700</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield code="i">is translation of</marc:subfield>
        <xsl:copy-of select="$agentSubfields"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[@code='t']"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[
                                                    contains('fhklmoprsdgn',@code) and 
                                                    preceding-sibling::marc:subfield[@code='t'] and 
                                                    following-sibling::marc:subfield[@code='l']
                                                 ]"/>
      </marc:datafield>
    </xsl:if>
    <xsl:if test="marc:subfield[@code='o']">
      <marc:datafield>
        <xsl:attribute name="tag">700</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield code="i">is arrangement of</marc:subfield>
        <xsl:copy-of select="$agentSubfields"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[@code='t']"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[
                                                    contains('fhklmoprsdgn',@code) and 
                                                    preceding-sibling::marc:subfield[@code='t'] and 
                                                    following-sibling::marc:subfield[@code='o']
                                                  ]"/>
      </marc:datafield>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield[@tag='110']">
    <xsl:variable name="agentSubfields">
      <xsl:apply-templates mode="copy" select="marc:subfield[contains('abcedgn',@code)][following-sibling::marc:subfield[@code='t']]"/>
    </xsl:variable>
    <marc:datafield>
      <xsl:attribute name="tag">110</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:copy-of select="$agentSubfields"/>
    </marc:datafield>
    <marc:datafield>
      <xsl:attribute name="tag">240</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:attribute name="ind2">0</xsl:attribute>
      <marc:subfield>
        <xsl:attribute name="code">a</xsl:attribute>
        <xsl:value-of select="marc:subfield[@code='t']"/>
      </marc:subfield>
      <xsl:apply-templates mode="copy" select="marc:subfield[contains('fhklmoprsdgn',@code)][preceding-sibling::marc:subfield[@code='t']]"/>
    </marc:datafield>
    
    <xsl:if test="marc:subfield[@code='l']">
      <marc:datafield>
        <xsl:attribute name="tag">710</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield code="i">is translation of</marc:subfield>
        <xsl:copy-of select="$agentSubfields"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[@code='t']"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[
                                                    contains('fhklmoprsdgn',@code) and 
                                                    preceding-sibling::marc:subfield[@code='t'] and 
                                                    following-sibling::marc:subfield[@code='l']
                                                 ]"/>
      </marc:datafield>
    </xsl:if>
    <xsl:if test="marc:subfield[@code='o']">
      <marc:datafield>
        <xsl:attribute name="tag">710</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield code="i">is arrangement of</marc:subfield>
        <xsl:copy-of select="$agentSubfields"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[@code='t']"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[
                                                    contains('fhklmoprsdgn',@code) and 
                                                    preceding-sibling::marc:subfield[@code='t'] and 
                                                    following-sibling::marc:subfield[@code='o']
                                                  ]"/>
      </marc:datafield>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield[@tag='111']">
    <xsl:variable name="agentSubfields">
      <xsl:apply-templates mode="copy" select="marc:subfield[contains('acejqdgn',@code)][following-sibling::marc:subfield[@code='t']]"/>
    </xsl:variable>
    <marc:datafield>
      <xsl:attribute name="tag">111</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:copy-of select="$agentSubfields"/>
    </marc:datafield>
    <marc:datafield>
      <xsl:attribute name="tag">240</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:attribute name="ind2">0</xsl:attribute>
      <marc:subfield>
        <xsl:attribute name="code">a</xsl:attribute>
        <xsl:value-of select="marc:subfield[@code='t']"/>
      </marc:subfield>
      <xsl:apply-templates mode="copy" select="marc:subfield[contains('fhklpstdgn',@code)][preceding-sibling::marc:subfield[@code='t']]"/>
    </marc:datafield>
    
    <xsl:if test="marc:subfield[@code='l']">
      <marc:datafield>
        <xsl:attribute name="tag">711</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield code="i">is translation of</marc:subfield>
        <xsl:copy-of select="$agentSubfields"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[@code='t']"/>
        <xsl:apply-templates mode="copy" select="marc:subfield[
                                                      contains('fhklpstdgn',@code) and 
                                                      preceding-sibling::marc:subfield[@code='t'] and 
                                                      following-sibling::marc:subfield[@code='l']
          ]"/>
      </marc:datafield>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='130']">
    <marc:datafield>
      <xsl:attribute name="tag">130</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
    </marc:datafield>
    
    <xsl:if test="marc:subfield[@code='l']">
      <marc:datafield>
        <xsl:attribute name="tag">730</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield code="i">is translation of</marc:subfield>
        <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6' and following-sibling::marc:subfield[@code='l']]"/>
      </marc:datafield>
    </xsl:if>
    <xsl:if test="marc:subfield[@code='o']">
      <marc:datafield>
        <xsl:attribute name="tag">730</xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <marc:subfield code="i">is arrangement of</marc:subfield>
        <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6' and following-sibling::marc:subfield[@code='o']]"/>
      </marc:datafield>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield[@tag='370']">
    <marc:datafield>
      <xsl:attribute name="tag">370</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[not(contains('abe6',@code))]"/>
    </marc:datafield>
  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='400'] |
                       marc:datafield[@tag='410'] |
                       marc:datafield[@tag='411']">
    <!--
        It is not a copy we want here.  We want to extract any titles that are different
        from the one in the 1XX and add them as 246s.  And we want to extract any names that 
        are different than that found in the 1XX and add them as related *name* access points.
      -->
    <!--
      <marc:datafield>
      <xsl:attribute name="tag"><xsl:value-of select="concat('7',substring(@tag,2,2))"/></xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2">4</xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[not(contains('w6',@code))]"/>
    </marc:datafield>
    -->
    <!-- 
      We want to determine if the name in the 1XX matches the name in the 4XX *per record*.
      It is likely, for this comparison check, comparing a, b, c, e, j, and q, which are 
      mostly common across the 1XX fields and do *not* also pertain to the title, is 
      sufficient to determine equality.
    -->
    
    <xsl:variable name="df1XXname">
      <xsl:for-each select="../marc:datafield[@tag='100' or @tag='110' or @tag='111'][1]/marc:subfield[contains('abcejq',@code)]">
        <xsl:if test="position() > 1">
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="df4XXname">
      <xsl:for-each select="marc:subfield[contains('abcejq',@code)]">
        <xsl:if test="position() > 1">
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="$df1XXname != $df4XXname">
      <marc:datafield>
        <xsl:attribute name="tag"><xsl:value-of select="concat('7',substring(@tag,2,2))"/></xsl:attribute>
        <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
        <!-- No d, g, or n subfields after 't' -->
        <xsl:for-each select="marc:subfield[contains('abcejqdgn',@code)]">
          <xsl:if test="position()=1 or preceding-sibling::node()[not(contains('t',@code))]" >
            <xsl:apply-templates mode="copy" select="."/>
          </xsl:if> 
        </xsl:for-each>
      </marc:datafield>
    </xsl:if>
    
    <xsl:variable name="df1XXtitle">
      <xsl:apply-templates mode="df1XXtitle" select="../marc:datafield[
                                                        @tag='130' or 
                                                        @tag='100' or 
                                                        @tag='110' or 
                                                        @tag='111']"
      />
    </xsl:variable>
    <xsl:variable name="df4XXtitle">
      <xsl:for-each select="marc:subfield[contains('tfhklmoprs',@code)]">
        <xsl:if test="position() > 1">
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="$df1XXtitle != $df4XXtitle">
      <marc:datafield>
        <xsl:attribute name="tag">246</xsl:attribute>
        <xsl:attribute name="ind1">3</xsl:attribute> <!-- no note, added entry -->
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute> <!-- no type specified yes? -->
        <!-- d, g, or n subfields after 't' -->
        <xsl:variable name="df246title">
          <xsl:for-each select="marc:subfield[contains('tfhklmoprsdgn',@code)]">
            <xsl:if test="string(@code) = 't' or preceding-sibling::node()[contains('t',@code)]" >
              <xsl:if test="position() > 1">
                <xsl:text> </xsl:text>
              </xsl:if>
              <xsl:value-of select="."/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <marc:subfield>
          <xsl:attribute name="code">a</xsl:attribute>
          <xsl:value-of select="normalize-space($df246title)"/>
        </marc:subfield>
      </marc:datafield>
    </xsl:if>

  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='430']">
    <!--
    <marc:datafield>
      <xsl:attribute name="tag">730</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:attribute name="ind2">4</xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[not(contains('w6',@code))]"/>
    </marc:datafield>
    -->
    <xsl:variable name="df1XXtitle">
      <xsl:apply-templates mode="df1XXtitle" select="../marc:datafield[
        @tag='130' or 
        @tag='100' or 
        @tag='110' or 
        @tag='111']"
      />
    </xsl:variable>
    <xsl:variable name="df4XXtitle">
      <xsl:for-each select="marc:subfield[contains('adfghklmnoprst',@code)]">
        <xsl:if test="position() > 1">
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="$df1XXtitle != $df4XXtitle">
      <marc:datafield>
        <xsl:attribute name="tag">246</xsl:attribute>
        <xsl:attribute name="ind1">3</xsl:attribute> <!-- no note, added entry -->
        <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute> <!-- no type specified yes? -->
        <!-- d, g, or n subfields after 't' -->
        <xsl:variable name="df246title">
          <xsl:for-each select="marc:subfield[contains('adfghklmnoprst',@code)]">
            <xsl:if test="position() > 1">
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:value-of select="."/>
          </xsl:for-each>
        </xsl:variable>
        <marc:subfield>
          <xsl:attribute name="code">a</xsl:attribute>
          <xsl:value-of select="normalize-space($df246title)"/>
        </marc:subfield>
      </marc:datafield>
    </xsl:if>
  </xsl:template>

  <xsl:template match="marc:datafield[@tag='500'] |
                       marc:datafield[@tag='510'] |
                       marc:datafield[@tag='511']">
    <marc:datafield>
      <xsl:attribute name="tag"><xsl:value-of select="concat('7',substring(@tag,2,2))"/></xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[not(contains('w6',@code))]"/>
      <xsl:if test="marc:subfield[@code='t'] and not(marc:subfield[@code='i'])">
        <marc:subfield>
          <xsl:attribute name="code">i</xsl:attribute>
          <xsl:choose>
            <xsl:when test="substring(marc:subfield[@code='w'],1,1)='f'">based on</xsl:when>
            <xsl:otherwise>related work</xsl:otherwise>
          </xsl:choose>
        </marc:subfield>
      </xsl:if>
    </marc:datafield>
  </xsl:template>

  <xsl:template match="marc:datafield[@tag='530']">
    <marc:datafield>
      <xsl:attribute name="tag">730</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[not(contains('w6',@code))]"/>
      <xsl:if test="not(marc:subfield[@code='i'])">
        <marc:subfield>
          <xsl:attribute name="code">i</xsl:attribute>
          <xsl:choose>
            <xsl:when test="substring(marc:subfield[@code='w'],1,1)='f'">based on</xsl:when>
            <xsl:otherwise>related work</xsl:otherwise>
          </xsl:choose>
        </marc:subfield>
      </xsl:if>
    </marc:datafield>
  </xsl:template>

  <!-- copy to MARC bib 46X field -->
  <xsl:template match="marc:datafield[@tag='640'] |
                       marc:datafield[@tag='641'] |
                       marc:datafield[@tag='642'] |
                       marc:datafield[@tag='643'] |
                       marc:datafield[@tag='644'] |
                       marc:datafield[@tag='645'] |
                       marc:datafield[@tag='646']">
    <xsl:variable name="vTargetTag">
      <xsl:choose>
        <xsl:when test="@tag='640'">462</xsl:when>
        <xsl:when test="@tag='641'">463</xsl:when>
        <xsl:when test="@tag='642'">464</xsl:when>
        <xsl:when test="@tag='643'">465</xsl:when>
        <xsl:when test="@tag='644'">466</xsl:when>
        <xsl:when test="@tag='645'">467</xsl:when>
        <xsl:when test="@tag='646'">468</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <marc:datafield>
      <xsl:attribute name="tag"><xsl:value-of select="$vTargetTag"/></xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
    </marc:datafield>
  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='667']">
    <marc:datafield>
      <xsl:attribute name="tag">588</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
    </marc:datafield>
  </xsl:template>
  
  <!-- copy to MARC bib 587 field -->
  <xsl:template match="marc:datafield[@tag='670'] |
                       marc:datafield[@tag='675']">
    <marc:datafield>
      <xsl:attribute name="tag">587</xsl:attribute>
      <xsl:attribute name="ind1">
        <xsl:choose>
          <xsl:when test="@tag='670'"><xsl:text> </xsl:text></xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="ind2"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
    </marc:datafield>
  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='678']">
    <marc:datafield>
      <xsl:attribute name="tag">545</xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
    </marc:datafield>
  </xsl:template>
  
  <xsl:template match="marc:datafield[@tag='700'] |
                       marc:datafield[@tag='710'] |
                       marc:datafield[@tag='711'] |
                       marc:datafield[@tag='730']">
    <marc:datafield>
      <xsl:attribute name="tag"><xsl:value-of select="@tag"/></xsl:attribute>
      <xsl:attribute name="ind1">
        <xsl:choose>
          <xsl:when test="@tag='730'">0</xsl:when>
          <xsl:otherwise><xsl:value-of select="@ind1"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="ind2"><xsl:text> </xsl:text></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
      <xsl:if test="contains('012356',@ind2) and not(marc:subfield[@code='2'])">
        <marc:subfield>
          <xsl:attribute name="code">2</xsl:attribute>
          <xsl:choose>
            <xsl:when test="@ind2='0'">lcsh</xsl:when>
            <xsl:when test="@ind2='1'">lcshac</xsl:when>
            <xsl:when test="@ind2='2'">mesh</xsl:when>
            <xsl:when test="@ind2='3'">nal</xsl:when>
            <xsl:when test="@ind2='5'">cash</xsl:when>
            <xsl:when test="@ind2='6'">rvm</xsl:when>
          </xsl:choose>
        </marc:subfield>
      </xsl:if>
    </marc:datafield>
  </xsl:template>

  <!-- control fields copied directly from mta to mbh -->
  <xsl:template match="marc:controlfield[@tag='001'] |
                       marc:controlfield[@tag='003'] |
                       marc:controlfield[@tag='005']">
    <xsl:apply-templates mode="copy" select="."/>
  </xsl:template>

  <!-- data fields copied from mta to mbh (excluding $6) -->
  <xsl:template match="marc:datafield[@tag='010'] |
                       marc:datafield[@tag='016'] |
                       marc:datafield[@tag='020'] |
                       marc:datafield[@tag='022'] |
                       marc:datafield[@tag='024'] |
                       marc:datafield[@tag='031'] |
                       marc:datafield[@tag='034'] |
                       marc:datafield[@tag='035'] |
                       marc:datafield[@tag='042'] |
                       marc:datafield[@tag='043'] |
                       marc:datafield[@tag='045'] |
                       marc:datafield[@tag='050'] |
                       marc:datafield[@tag='052'] |
                       marc:datafield[@tag='053'] |
                       marc:datafield[@tag='055'] |
                       marc:datafield[@tag='060'] |
                       marc:datafield[@tag='066'] |
                       marc:datafield[@tag='070'] |
                       marc:datafield[@tag='072'] |
                       marc:datafield[@tag='075'] |
                       marc:datafield[@tag='080'] |
                       marc:datafield[@tag='082'] |
                       marc:datafield[@tag='083'] |
                       marc:datafield[@tag='086'] |
                       marc:datafield[@tag='090'] |
                       marc:datafield[@tag='335'] |
                       marc:datafield[@tag='336'] |
                       marc:datafield[@tag='348'] |
                       marc:datafield[@tag='377'] |
                       marc:datafield[@tag='380'] |
                       marc:datafield[@tag='381'] |
                       marc:datafield[@tag='382'] |
                       marc:datafield[@tag='383'] |
                       marc:datafield[@tag='384'] |
                       marc:datafield[@tag='385'] |
                       marc:datafield[@tag='386'] |
                       marc:datafield[@tag='388'] |
                       marc:datafield[@tag='856'] |
                       marc:datafield[@tag='883'] |
                       marc:datafield[@tag='884'] |
                       marc:datafield[@tag='885']">
    <marc:datafield>
      <xsl:attribute name="tag"><xsl:value-of select="@tag"/></xsl:attribute>
      <xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
      <xsl:attribute name="ind2"><xsl:value-of select="@ind2"/></xsl:attribute>
      <xsl:apply-templates mode="copy" select="marc:subfield[@code != '6']"/>
    </marc:datafield>
  </xsl:template>

  <!-- All other fields are ignored -->
  <xsl:template match="marc:controlfield|marc:datafield"/>
  
  <!-- warn about other elements -->
  <xsl:template match="*">

    <xsl:message terminate="no">
      <xsl:text>WARNING: Unmatched element: </xsl:text><xsl:value-of select="name()"/>
    </xsl:message>

    <xsl:apply-templates/>

  </xsl:template>

  <!-- named templates -->
  <!-- 040 $e from 008/10 -->
  <xsl:template name="p040e">
    <xsl:param name="p008-10"/>
    <xsl:choose>
      <xsl:when test="$p008-10='a'">pre-AACR</xsl:when>
      <xsl:when test="contains('bcd',$p008-10)">aacr</xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- utility templates -->
  <!-- copy without namespace nodes for marc to avoid extra xmlns declarations -->
  <xsl:template match="*" mode="copy">
    <xsl:choose>
      <xsl:when test="namespace-uri()='http://www.loc.gov/MARC21/slim'">
        <xsl:element name="marc:{local-name()}">
          <xsl:apply-templates select="@*|node()" mode="copy"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{name()}" namespace="{namespace-uri()}">
          <xsl:apply-templates select="@*|node()" mode="copy"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
    
  <xsl:template match="@*|text()|comment()" mode="copy">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="marc:datafield" mode="df1XXtitle">
    <xsl:choose>
      <xsl:when test="@tag = '130'">
        <xsl:for-each select="marc:subfield[contains('adfghklmnoprst',@code)]">
          <xsl:if test="position() > 1">
            <xsl:text> </xsl:text>
          </xsl:if>
          <xsl:value-of select="."/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="marc:subfield[contains('tfhklmoprs',@code)]">
          <xsl:if test="position() > 1">
            <xsl:text> </xsl:text>
          </xsl:if>
          <xsl:value-of select="."/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
