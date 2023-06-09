<?xml version="1.0" encoding="UTF-8"?>
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright (c) Contributors to the StructureVisualization Project. -->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/2000/svg"
                xmlns:sv="urn:example:sv"
                xmlns:svg="http://www.w3.org/2000/svg"
                xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
                xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd">

  <!-- doctype-public="-//W3C//DTD SVG 1.1//EN" -->
  <xsl:output method="xml"
              indent="yes"
              encoding="UTF-8"
              standalone="no"
              xmlns:svg="http://www.w3.org/2000/svg"
              media-type="image/svg" />

  <xsl:variable name="unitsize" select="8" />
  <xsl:variable name="indentFactor" select="2" />
  <xsl:variable name="dotRadius" select="2.5" />
  <xsl:variable name="tagMargin" select="2" />
  <xsl:variable name="tagPadding" select="1.5" />
  <xsl:variable name="primfontW" select="5" />
  <xsl:variable name="primfontH" select="$primfontW*2" />
  <xsl:variable name="totalwidth" select="24" />
  <xsl:variable name="layerContentX" select="$unitsize * 1.5" />
  <xsl:variable name="layerContentY" select="$unitsize * 3.5" />
  <xsl:variable name="uidSizeLimit" select="6" />

  <!-- All template application is explicit. -->
  <xsl:template match="node()" />
  <xsl:template match="node()" mode="autodefs" />
  <xsl:template match="node()" mode="tag_string" />
  <xsl:template match="node()" mode="right_aligned" />
  <xsl:template match="node()" mode="required_width" />
  <xsl:template match="node()" mode="contents_width" />

  <!-- ROOT ENTITIES -->
  <!-- ############# -->

  <xsl:template match="/">
    <xsl:apply-templates select="sv:sv" />
  </xsl:template>

  <xsl:template match="sv:sv">
    <svg id="diagram"
         width="200"
         height="512"
         version="1.1"
         viewBox="0 0 200 512"
         xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
         xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
         xmlns="http://www.w3.org/2000/svg"
         xmlns:svg="http://www.w3.org/2000/svg">
      <defs id="autodefs">
        <xsl:apply-templates mode="autodefs" />
      </defs>
      <xsl:apply-templates />
    </svg>
  </xsl:template>

  <xsl:template match="sv:defs" />

  <xsl:template match="sv:stacks">
    <g id="stacks"
       inkscape:groupmode="layer">
      <xsl:apply-templates select="sv:stack[1]" />
    </g>
  </xsl:template>

  <!-- / ROOT ENTITIES -->



  <!-- CONTENT WIDTH CALCULATIONS -->
  <!-- ########################## -->

  <xsl:key name="find_tag" match="/sv:sv/sv:defs/sv:deftag" use="@id"/>

  <xsl:template name="extract_name">
    <xsl:param name="path" select="@path" />
    <xsl:choose>
      <xsl:when test="contains($path, '/')">
        <xsl:call-template name="extract_name">
          <xsl:with-param name="path" select="substring-after($path, '/')" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$path" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get_max">
    <xsl:param name="a" />
    <xsl:param name="b" />
    <xsl:choose>
      <xsl:when test="$a &gt; $b">
        <xsl:value-of select="$a" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$b" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="make_tag_string">
    <xsl:param name="value" />
    <xsl:value-of select="translate($value,
                          'abcdefghijklmnopqrstuvwxyz-',
                          'ABCDEFGHIJKLMNOPQRSTUVWXYZ ')" />
  </xsl:template>

  <xsl:template match="sv:deftag" mode="tag_string">
    <xsl:variable name="text">
      <xsl:choose>
        <xsl:when test="@text">
          <xsl:value-of select="@text" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="make_tag_string">
            <xsl:with-param name="value" select="@id" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="@value">
        <xsl:value-of select="concat($text, ': &#34;', @value, '&#34;')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="required_tag_width">
    <xsl:param name="value" />
    <xsl:value-of select="string-length($value)*3 + 2 + $tagPadding*2" />
  </xsl:template>

  <xsl:template match="sv:taglist" mode="required_width">
    <xsl:param name="index" select="count(sv:tag | sv:gap)" />
    <xsl:param name="current_sum" select="0" />
    <xsl:variable name="tagid" select="(sv:tag | sv:gap)[$index]/@name" />
    <xsl:variable name="width">
      <xsl:call-template name="required_tag_width">
        <xsl:with-param name="value">
          <xsl:apply-templates select="key('find_tag', $tagid)" mode="tag_string" />
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:apply-templates select="." mode="required_width">
          <xsl:with-param name="index" select="$index - 1" />
          <xsl:with-param name="current_sum" select="$current_sum + $width + $tagMargin" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$current_sum" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sv:prim" mode="contents_width">
    <xsl:param name="index" select="count(sv:taglist)" />
    <xsl:param name="current_max" select="0" />
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:variable name="w">
          <xsl:apply-templates select="sv:taglist[$index]" mode="required_width" />
        </xsl:variable>
        <xsl:apply-templates select="." mode="contents_width">
          <xsl:with-param name="current_max">
            <xsl:call-template name="get_max">
              <xsl:with-param name="a" select="$current_max" />
              <xsl:with-param name="b" select="$w" />
            </xsl:call-template>
          </xsl:with-param>
          <xsl:with-param name="index" select="$index - 1" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$current_max" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sv:prim" mode="required_width">
    <xsl:variable name="name">
      <xsl:call-template name="extract_name" />
    </xsl:variable>
    <xsl:variable name="prim_w" select="string-length($name)*$primfontW" />
    <xsl:variable name="tag_w">
      <xsl:apply-templates select="." mode="contents_width" />
    </xsl:variable>
    <xsl:variable name="max_row">
      <xsl:call-template name="get_max">
        <xsl:with-param name="a" select="$prim_w" />
        <xsl:with-param name="b" select="$tag_w" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="indent">
      <xsl:apply-templates select="." mode="prim_indent" />
    </xsl:variable>
    <xsl:value-of select="$max_row + $indent*$indentFactor*$unitsize" />
  </xsl:template>

  <xsl:template match="sv:layer" mode="contents_width">
    <xsl:param name="index" select="count(sv:prim)" />
    <xsl:param name="current_max" select="0" />
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:apply-templates select="." mode="contents_width">
          <xsl:with-param name="index" select="$index - 1" />
          <xsl:with-param name="current_max">
            <xsl:call-template name="get_max">
              <xsl:with-param name="a" select="$current_max" />
              <xsl:with-param name="b">
                <xsl:apply-templates select="sv:prim[$index]" mode="required_width" />
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$current_max" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sv:layer" mode="required_width">
    <xsl:variable name="visButtonOffset" select="$unitsize" />
    <xsl:variable name="width_required_for_layer_path"
                  select="string-length(@path)*$primfontW + $visButtonOffset" />
    <xsl:variable name="required_layer_width">
      <xsl:call-template name="get_max">
        <xsl:with-param name="a" select="$width_required_for_layer_path" />
        <xsl:with-param name="b">
          <xsl:apply-templates select="." mode="contents_width" />
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="18.5*2 + $required_layer_width" />
  </xsl:template>

  <xsl:template match="sv:stack" mode="required_width">
    <xsl:param name="index" select="count(sv:layer)" />
    <xsl:param name="current_max" select="0" />
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:apply-templates select="." mode="required_width">
          <xsl:with-param name="index" select="$index - 1" />
          <xsl:with-param name="current_max">
            <xsl:call-template name="get_max">
              <xsl:with-param name="a" select="$current_max" />
              <xsl:with-param name="b">
                <xsl:apply-templates select="sv:layer[$index]" mode="required_width" />
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$current_max" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- / CONTENT WIDTH CALCULATIONS -->



  <!-- CONTENT HEIGHT CALCULATIONS -->
  <!-- ########################## -->

  <xsl:template match="sv:prim" mode="required_prim_vline">
    <xsl:variable name="tag_and_bar_height">
      <xsl:call-template name="get_max">
        <xsl:with-param name="a" select="1" />
        <xsl:with-param name="b" select="count(sv:taglist)" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$tag_and_bar_height+2" />
  </xsl:template>

  <xsl:template match="sv:prim" mode="required_prim_vspan">
    <xsl:variable name="indent">
      <xsl:apply-templates mode="prim_indent" select="." />
    </xsl:variable>
    <xsl:variable name="following_indent">
      <xsl:apply-templates mode="prim_indent" select="following-sibling::sv:prim[1]" />
    </xsl:variable>
    <xsl:variable name="last_prim" select="not(following-sibling::sv:prim)" />
    <xsl:variable name="required_vline">
      <xsl:apply-templates select="." mode="required_prim_vline" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="($indent &lt; $following_indent) or $last_prim">
        <xsl:value-of select="$required_vline" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$required_vline + 2" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sv:layer" mode="contents_height">
    <xsl:param name="index" select="count(sv:prim)" />
    <xsl:param name="current_sum" select="0" />
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:variable name="h">
          <xsl:choose>
            <xsl:when test="sv:prim[$index][@vspan]">
              <xsl:value-of select="sv:prim[$index]/@vspan" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="sv:prim[$index]"
                                   mode="required_prim_vspan" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:apply-templates select="." mode="contents_height">
          <xsl:with-param name="current_sum" select="$current_sum + $h" />
          <xsl:with-param name="index" select="$index - 1" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$current_sum" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- / CONTENT HEIGHT CALCULATIONS -->



  <!-- STACK -->
  <!-- ##### -->

  <xsl:template name="write_info">
    <xsl:if test="@info">
      <xsl:attribute name="data-info">
        <xsl:value-of select="@info" />
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="sv:stack">
    <xsl:param name="originStack" />
    <xsl:param name="originArcId" />
    <xsl:param name="gridX" select="0" />
    <xsl:param name="gridY" select="0" />
    <xsl:variable name="width">
      <xsl:apply-templates select="." mode="required_width" />
    </xsl:variable>
    <xsl:variable name="idRootLayer">
      <xsl:apply-templates select="sv:layer[1]" mode="generate_layer_id">
        <xsl:with-param name="originArcId" select="$originArcId" />
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="idResolved" select="concat('stack_', $idRootLayer)" />
    <xsl:for-each select="(descendant::sv:tag | descendant::sv:gap)[@target]">
      <xsl:variable name="uid" select="generate-id()"/>
      <xsl:variable name="uidLength" select="string-length($uid)"/>
      <xsl:variable name="uidShort">
        <xsl:choose>
          <xsl:when test="$uidLength &gt; $uidSizeLimit">
            <xsl:value-of select="substring($uid, ($uidLength - $uidSizeLimit) + 1)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$uid" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="uidFlat" select="concat($originArcId, '&#xB7;', $uidShort)"/>
      <xsl:variable name="preceding_vspan">
        <xsl:apply-templates select="../../.." mode="contents_height">
          <xsl:with-param name="index" select="count(../../preceding-sibling::sv:prim)" />
        </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="indent">
        <xsl:apply-templates select="../.." mode="prim_indent" />
      </xsl:variable>
      <xsl:apply-templates select="//sv:stack[sv:layer[1]/@path = current()/@target]">
        <xsl:with-param name="gridX" select="$gridX + $indent*$indentFactor" />
        <xsl:with-param name="gridY" select="$gridY + $preceding_vspan" />
        <xsl:with-param name="originArcId" select="$uidFlat" />
        <xsl:with-param name="originStack" select="$idResolved" />
      </xsl:apply-templates>
    </xsl:for-each>
    <g id="{$idResolved}" data-gridX="{$gridX}" data-gridY="{$gridY}" data-width="{$width}">
      <xsl:if test="$originStack">
        <xsl:attribute name="data-parent">
          <xsl:value-of select="$originStack" />
        </xsl:attribute>
      </xsl:if>
      <xsl:attribute name="inkscape:groupmode">layer</xsl:attribute>
      <xsl:apply-templates>
        <xsl:sort select="position()" data-type="number" order="descending" />
        <xsl:with-param name="w" select="$width" />
        <xsl:with-param name="stackX" select="$gridX" />
        <xsl:with-param name="stackY" select="$gridY" />
        <xsl:with-param name="originArcId" select="$originArcId" />
      </xsl:apply-templates>
    </g>
  </xsl:template>

  <!-- / STACK -->



  <!-- CONTAINER -->
  <!-- ######### -->

  <xsl:template name="add_bg_rect">
    <!-- <rect -->
    <!--     class="bg-rect" -->
    <!--     width="200" -->
    <!--     height="512" -->
    <!--     x="0" -->
    <!--     y="0" -->
    <!--     inkscape:label="bg" -->
    <!--     sodipodi:insensitive="true" /> -->
  </xsl:template>

  <xsl:template name="generate_layer_header_path">
    <xsl:param name="w" select="0" />
    <xsl:variable name="oX" select="2.25" />
    <xsl:variable name="oR" select="$unitsize - 2.25" />
    <xsl:attribute name="d">
      <xsl:value-of
          select="concat(
                  'M ', $unitsize*1.5, ' ', $unitsize*2,
                  ' l ', $oX, ' ', -$unitsize,
                  ' a ', $oR, ' ', $oR, ' 0 0 1 ', $oR, ' ', -$unitsize*0.5,
                  ' h ', ($w)-($unitsize*4),
                  ' a ', $oR, ' ', $oR, ' 0 0 1 ', $oR, ' ',  $unitsize*0.5,
                  ' l ', $oX, ' ', $unitsize
                  )" />
    </xsl:attribute>
  </xsl:template>

  <xsl:template name="add_container">
    <xsl:param name="w" />
    <xsl:param name="h" />
    <xsl:param name="t" />
    <xsl:call-template name="add_bg_rect" />
    <g opacity="0.75"
       inkscape:label="container_bg"
       class="container-bg"
       transform="{$t}">
      <rect class="base-style generic-style container-bg-rect"
            width="{$w}" height="{$h}" x="4" y="16" ry="4"
            inkscape:label="container" />
    </g>
    <g opacity="1"
       inkscape:label="container"
       transform="{$t}">
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="not(preceding::sv:layer)">root-container</xsl:when>
          <xsl:otherwise>container</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <path
          class="base-style generic-style container-base container-path"
          style="stroke:none"
          sodipodi:nodetypes="cccc">
        <xsl:call-template name="generate_layer_header_path">
          <xsl:with-param name="w" select="$w" />
        </xsl:call-template>
      </path>
      <rect class="base-style generic-style container-base container-rect"
            width="{$w}" height="{$h}"
            x="4" y="16" ry="4"
            inkscape:label="container"
            tabindex="0" />
      <text class="layer-name-string" x="18.5" y="13.5">
        <xsl:value-of select="@path" />
      </text>
    </g>
  </xsl:template>

  <!-- / CONTAINER -->



  <!-- LAYER -->
  <!-- ##### -->

  <xsl:template match="sv:layer" mode="generate_layer_id">
    <xsl:param name="originArcId" />
    <xsl:value-of select="concat(
                          translate(@path, './', '__'),
                          $originArcId)" />
  </xsl:template>

  <xsl:template name="generate_layer_specific_transform">
    <xsl:param name="offsetX" select="0" />
    <xsl:param name="stackX" />
    <xsl:param name="stackY" />
    <xsl:value-of select="concat( 'translate(',
                          $unitsize*$stackX + $offsetX, ',',
                          $unitsize*$stackY,
                          ')' )" />
  </xsl:template>

  <xsl:template match="sv:layer">
    <xsl:param name="w" />
    <xsl:param name="stackX" />
    <xsl:param name="stackY" />
    <xsl:param name="originArcId" />
    <xsl:variable name="idResolved">
      <xsl:apply-templates select="." mode="generate_layer_id">
        <xsl:with-param name="originArcId" select="$originArcId" />
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="left_align">
      <xsl:call-template name="generate_layer_specific_transform">
        <xsl:with-param name="stackX" select="$stackX" />
        <xsl:with-param name="stackY" select="$stackY" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="right_align">
      <xsl:call-template name="generate_layer_specific_transform">
        <xsl:with-param name="offsetX" select="$w" />
        <xsl:with-param name="stackX" select="$stackX" />
        <xsl:with-param name="stackY" select="$stackY" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="total_vspan">
      <xsl:apply-templates select="." mode="contents_height" />
    </xsl:variable>
    <g id="{concat('layer_', $idResolved)}">
      <xsl:call-template name="add_container">
        <xsl:with-param name="w" select="$w" />
        <xsl:with-param name="h" select="$unitsize*(2.5 + $total_vspan)" />
        <xsl:with-param name="t" select="$left_align" />
      </xsl:call-template>
      <g inkscape:label="right_aligned"
         class="right-aligned"
         transform="{$right_align}">
        <g class="content"
           transform="translate(-12,34)"
           inkscape:label="isa_column">
          <xsl:apply-templates select="sv:prim" mode="right_aligned" />
        </g>
        <xsl:apply-templates select="sv:custom" mode="right_aligned" />
      </g>
      <g inkscape:label="left_aligned"
         class="left-aligned"
         transform="{$left_align}">
        <xsl:apply-templates />
      </g>
    </g>
  </xsl:template>

  <!-- / LAYER -->



  <!-- LAYER CONTENTS -->
  <!-- ############## -->

  <xsl:template match="sv:custom[not(@align) or @align = 'left']">
    <g class="{@class}" inkscape:label="custom">
      <xsl:copy-of select="*" />
    </g>
  </xsl:template>

  <xsl:template match="sv:custom[@align and @align = 'right']" mode="right_aligned">
    <g class="{@class}" inkscape:label="custom">
      <xsl:copy-of select="*" />
    </g>
  </xsl:template>

  <!-- Example: -->
  <!-- <sv:prim path="/x" isa="xform" barSkip="1" barDraw="1" vspan="4" vline="14" /> -->

  <xsl:template name="generate_prim_specific_transform">
    <xsl:param name="offsetX" select="0" />
    <xsl:variable name="preceding_vspan">
      <xsl:apply-templates select=".." mode="contents_height">
        <xsl:with-param name="index" select="count(preceding-sibling::sv:prim)" />
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="concat('translate(',
                          $offsetX, ',',
                          $unitsize*$preceding_vspan, ')')" />
  </xsl:template>

  <xsl:template match="sv:prim" mode="prim_indent">
    <xsl:value-of select="string-length(@path)
                          - string-length(translate(@path, '/', '')) - 1" />
  </xsl:template>

  <xsl:template name="prim_transform">
    <xsl:variable name="indent">
      <xsl:apply-templates select="." mode="prim_indent" />
    </xsl:variable>
    <xsl:attribute name="transform">
      <xsl:call-template name="generate_prim_specific_transform">
        <xsl:with-param name="offsetX" select="$indent*$indentFactor*$unitsize" />
      </xsl:call-template>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="sv:prim">
    <xsl:variable name="default" select="concat('/', ../@defaultPrim) = @path" />
    <xsl:variable name="name">
      <xsl:call-template name="extract_name" />
    </xsl:variable>
    <xsl:variable name="primNameText">
      <text class="prim-name-string" x="18.5" y="30.75">
        <xsl:value-of select="$name" />
      </text>
    </xsl:variable>
    <xsl:variable name="spec">
      <xsl:choose>
        <xsl:when test="@spec"><xsl:value-of select="@spec" /></xsl:when>
        <xsl:otherwise>def</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="treat_as_default"
                  select="$default and preceding::sv:layer" />
    <xsl:if test="$treat_as_default">
      <g inkscape:label="defaultprim" class="expanded-modes">
        <xsl:call-template name="prim_transform" />
        <xsl:copy-of select="$primNameText" />
      </g>
    </xsl:if>
    <g class="content" inkscape:label="{concat('prim-', $name)}">
      <xsl:call-template name="prim_transform" />
      <xsl:if test="not($treat_as_default)">
        <xsl:copy-of select="$primNameText" />
      </xsl:if>
      <xsl:variable name="vline">
        <xsl:call-template name="get_max">
          <xsl:with-param name="a" select="sum(@vline)" />
          <xsl:with-param name="b">
            <xsl:apply-templates select="." mode="required_prim_vline" />
          </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <path class="spec-pline">
        <xsl:attribute name="d">
          <xsl:value-of
              select="concat(
                      ' M ', $layerContentX - $indentFactor*$unitsize, ',', $layerContentY,
                      ' h ', $unitsize*$indentFactor - $dotRadius,
                      ' m ', $dotRadius, ', ', $dotRadius,
                      ' v ', $vline * $unitsize - ($dotRadius - .5)
                      )" />
        </xsl:attribute>
        <xsl:attribute name="style">
          <xsl:choose>
            <xsl:when test="$spec = 'over'">
              <xsl:value-of select="'stroke-dasharray:2, 2'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'stroke-dasharray:none'" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </path>
      <use href="#spec-dot-{$spec}" x="12" y="28" />
      <xsl:apply-templates />
    </g>
  </xsl:template>

  <xsl:template match="*" mode="right_aligned" />

  <xsl:template match="sv:prim[@isa]" mode="right_aligned">
    <xsl:variable name="transform">
      <xsl:call-template name="generate_prim_specific_transform" />
    </xsl:variable>
    <xsl:variable name="barDraw" select="sum(@barDraw)" />
    <xsl:variable name="barSkip" select="sum(@barSkip)" />
    <use href="#isa-{@isa}" transform="{$transform}" />
    <xsl:if test="$barSkip">
      <use href="#bar-{$barSkip}-path" style="stroke-opacity:0.2"
           transform="{$transform}" x="16" y="7.5" />
    </xsl:if>
    <xsl:if test="$barDraw">
      <use href="#bar-{$barDraw}-path" style="stroke-opacity:1.0"
           transform="{$transform}" x="16" y="{7.5 + $barSkip*2}" />
    </xsl:if>
  </xsl:template>

  <xsl:template name="tag_loop">
    <xsl:param name="index" select="count(preceding-sibling::sv:tag | preceding-sibling::sv:gap)" />
    <xsl:param name="offset" select="0" />
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:variable name="tagid" select="(../sv:tag | ../sv:gap)[$index]/@name" />
        <xsl:variable name="width">
          <xsl:call-template name="required_tag_width">
            <xsl:with-param name="value">
              <xsl:apply-templates select="key('find_tag', $tagid)" mode="tag_string" />
            </xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="tag_loop">
          <xsl:with-param name="index" select="$index - 1" />
          <xsl:with-param name="offset" select="$offset + $width + $tagMargin" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$offset" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Example: -->
  <!-- <sv:taglist> -->
  <!--   <sv:gap name="custom-data" /> -->
  <!--   <sv:tag name="asset-info" /> -->
  <!-- </sv:taglist> -->

  <xsl:template match="sv:taglist">
    <xsl:apply-templates>
      <xsl:with-param name="row_index"
                      select="count(preceding-sibling::sv:taglist)" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="sv:tag | sv:gap">
    <xsl:param name="row_index" />
    <xsl:variable name="x">
      <xsl:call-template name="tag_loop" />
    </xsl:variable>
    <xsl:variable
        name="transform"
        select="concat(
                'translate(',
                20 + $x,
                ',',
                34 + $row_index*$unitsize,
                ')'
                )" />
    <use href="#{local-name()}-{@name}" transform="{$transform}">
      <xsl:call-template name="write_info" />
    </use>
  </xsl:template>

  <!-- / LAYER CONTENTS -->



  <!-- DEFS -->
  <!-- #### -->

  <xsl:template name="tag_text_node">
    <xsl:param name="value" />
    <xsl:param name="width" />
    <text class="prim-tag-string" x="{$tagPadding}" y="5">
      <xsl:if test="$width">
        <xsl:attribute name="textLength">
          <xsl:value-of select="$width - $tagPadding*2" />
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$value" />
    </text>
  </xsl:template>

  <xsl:template match="sv:deftag">
    <xsl:variable name="tagString">
      <xsl:apply-templates select="." mode="tag_string" />
    </xsl:variable>
    <xsl:variable name="width">
      <xsl:call-template name="required_tag_width">
        <xsl:with-param name="value" select="$tagString" />
      </xsl:call-template>
    </xsl:variable>
    <g id="tag-{@id}">
      <xsl:call-template name="write_info" />
      <rect
          class="base-style prim-tag"
          width="{$width}"
          height="6"
          ry="1">
        <xsl:attribute name="style">
          <xsl:choose>
            <xsl:when test="@color">
              <xsl:value-of select="concat('fill:', @color)" />
            </xsl:when>
            <xsl:when test="@type = 'meta'">
              <xsl:value-of select="'fill:#500025'" />
            </xsl:when>
            <xsl:when test="@type = 'kind'">
              <xsl:value-of select="'fill:#0A5040'" />
            </xsl:when>
            <xsl:when test="@type = 'comp'">
              <xsl:value-of select="'fill:#952A05'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'fill:#333333'" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </rect>
      <xsl:call-template name="tag_text_node">
        <xsl:with-param name="value" select="$tagString" />
        <xsl:with-param name="width" select="$width" />
      </xsl:call-template>
    </g>

    <g id="gap-{@id}">
      <rect
          class="base-style prim-gap"
          width="{$width}"
          height="6"
          ry="1" />
    </g>
  </xsl:template>

  <xsl:template name="generate_content_bars">
    <xsl:param name="index" select="0" />
    <xsl:param name="limit" select="0" />
    <xsl:param name="value" />
    <xsl:if test="$index &lt;= $limit">
      <xsl:attribute name="d"><xsl:value-of select="$value" /></xsl:attribute>
      <xsl:call-template name="generate_content_bars">
        <xsl:with-param name="index" select="$index + 1" />
        <xsl:with-param name="limit" select="$limit" />
        <xsl:with-param name="value" select="concat($value, 'M 0,', $index*2, ' h 3 ')" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="sv:stacks" mode="autodefs">
    <!-- WARNING: Beginning of probably slow templates. -->
    <xsl:for-each select="//sv:prim[@barDraw
                          and not(@barDraw = preceding::sv:prim/@barDraw)
                          and not(@barDraw = preceding::sv:prim/@barSkip)]">
      <path id="bar-{@barDraw}-path" class="content-bar">
        <xsl:call-template name="generate_content_bars">
          <xsl:with-param name="limit" select="@barDraw" />
        </xsl:call-template>
      </path>
    </xsl:for-each>
    <xsl:for-each select="//sv:prim[@barSkip
                          and not(@barSkip = preceding::sv:prim/@barDraw)
                          and not(@barSkip = preceding::sv:prim/@barSkip)]">
      <path id="bar-{@barSkip}-path" class="content-bar">
        <xsl:call-template name="generate_content_bars">
          <xsl:with-param name="limit" select="@barSkip" />
        </xsl:call-template>
      </path>
    </xsl:for-each>
    <xsl:for-each select="//sv:prim[@isa and not(@isa = preceding::sv:prim/@isa)]">
      <g id="isa-{@isa}">
        <rect
            class="isa-rect"
            width="19"
            height="6"
            ry="1" />
        <xsl:call-template name="tag_text_node">
          <xsl:with-param name="value">
            <xsl:call-template name="make_tag_string">
              <xsl:with-param name="value" select="@isa" />
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </g>
    </xsl:for-each>
    <!-- WARNING: End of probably slow templates. -->
  </xsl:template>

  <xsl:template match="sv:defs" mode="autodefs">
    <style>
      .base-style
      {
      stroke-linejoin:round;
      stop-color:#000000;

      /* Likely redundant: */
      fill-opacity:1;
      stroke-dasharray:none;
      stroke-opacity:1;
      }

      .generic-style
      {
      stroke-linecap:square;

      /* Likely redundant: */
      stroke-miterlimit:4;
      stroke-dashoffset:0.57735;
      font-variation-settings:normal;
      }

      .prim-tag
      {
      stroke:#000000;
      stroke-width:0.5;
      }

      .prim-gap
      {
      stroke:#333333;
      stroke-width:0.5;
      opacity:0.1;
      fill:none;
      }

      .prim-tag-string
      {
      font-size:6px;
      font-family:'Ubuntu Condensed';
      fill:#ececec;
      }

      .prim-name-string
      {
      font-size:<xsl:value-of select="$primfontH" />px;
      font-family:Ubuntu Mono;
      line-height:1.25;
      font-weight:normal;

      /* Animated transition: */
      transition: text-shadow 250ms;

      /* Likely redundant: */
      font-style:normal;
      font-weight:normal;
      -inkscape-font-specification:Ubuntu;
      font-variant:normal;
      font-stretch:normal;
      }

      .prim-name-string:hover
      {
      text-shadow: #000000 0px 0px 2px;
      }

      .layer-name-string
      {
      font-weight:bold;
      font-size:10px;
      line-height:1.25;
      font-family:Ubuntu Mono;
      fill:#222222;
      stroke:none;
      text-shadow: 2px 2px 4px #FFFFFF;

      /* Likely redundant: */
      font-style:normal;
      font-variant:normal;
      font-stretch:normal;
      -inkscape-font-specification:'Ubuntu, Bold';
      font-variant-ligatures:normal;
      font-variant-caps:normal;
      font-variant-numeric:normal;
      font-variant-east-asian:normal;
      display:inline;
      fill-opacity:1;
      }

      .bg-rect
      {
      display:none;
      fill:#ffcc00;
      stroke-width:0.5;
      -inkscape-stroke:none;
      stop-color:#000000;
      }

      .container-bg-rect
      {
      stroke-width:0.5;
      stroke:none;
      fill:#e6e6e6;
      }

      .container-base
      {
      stroke-opacity:0.25;
      stroke-width:0.5;
      stroke:#333333;
      }

      .container-path
      {
      -inkscape-stroke:none;
      fill:#ccdddd;
      }

      .container-rect
      {
      fill:none;
      }

      .isa-rect
      {
      stroke:#333333;
      stroke-width:0.5;
      stroke-dasharray:none;
      }

      .content-bar
      {
      fill:none;
      stroke:#333333;
      stroke-width:1;
      stroke-linecap:butt;
      stroke-linejoin:miter;
      stroke-dasharray:none;
      }

      .spec-dot
      {
      stroke:#CCCCCC;
      fill-opacity:1;
      stroke-width:1px;
      stroke-linecap:round;
      stroke-linejoin:round;
      stroke-dasharray:none;
      stroke-opacity:1;
      stop-color:#000000;
      }

      .spec-pline
      {
      fill:none;
      stroke:#CCCCCC;
      stroke-width:1;
      stroke-linecap:butt;
      stroke-linejoin:round;
      stroke-dashoffset:0;
      stroke-opacity:1;
      }

      .arc-arrow
      {
      fill:none;
      stroke:#000000;
      stroke-width:1px;
      stroke-linecap:butt;
      stroke-linejoin:miter;
      stroke-dasharray:1, 1;
      stroke-dashoffset:0;
      stroke-opacity:1;
      marker-start:url(#marker2);
      marker-end:url(#ConcaveTriangle);
      }
    </style>

    <circle
        id="spec-dot-def"
        class="spec-dot"
        style="fill:#444444"
        r="{$dotRadius}" />

    <circle
        id="spec-dot-class"
        class="spec-dot"
        style="fill:#F27B1F"
        r="{$dotRadius}" />

    <circle
        id="spec-dot-over"
        class="spec-dot"
        style="fill:none"
        r="{$dotRadius}" />

    <marker
        style="overflow:visible"
        id="marker2"
        refX="0"
        refY="0"
        orient="auto-start-reverse"
        inkscape:stockid="Concave triangle arrow"
        markerWidth="7.7"
        markerHeight="5.6"
        viewBox="0 0 7.7 5.6"
        inkscape:isstock="true"
        inkscape:collect="always"
        preserveAspectRatio="xMidYMid">
      <path
          transform="scale(0.7)"
          d="M -2,-4 9,0 -2,4 c 2,-2.33 2,-5.66 0,-8 z"
          style="fill:context-stroke;fill-rule:evenodd;stroke:none" />
    </marker>

    <marker
        style="overflow:visible"
        id="ConcaveTriangle"
        refX="0"
        refY="0"
        orient="auto-start-reverse"
        inkscape:stockid="Concave triangle arrow"
        markerWidth="7.7"
        markerHeight="5.6"
        viewBox="0 0 7.7 5.6"
        inkscape:isstock="true"
        inkscape:collect="always"
        preserveAspectRatio="xMidYMid">
      <path
          d="M 6.3,-2.8 -1.4,0 6.3,2.8 C 4.9,1.169 4.9,-1.162 6.3,-2.8 Z"
          style="fill:context-stroke;fill-rule:evenodd;stroke:none;stroke-width:0.7" />
    </marker>

    <linearGradient
        id="visibilityGrad"
        gradientUnits="userSpaceOnUse"
        x1="8"
        y1="5.75"
        x2="6.5"
        y2="4.5">
      <stop
          style="stop-color:#ffffff;stop-opacity:1;"
          offset="0" />
      <stop
          style="stop-color:#ffffff;stop-opacity:0;"
          offset="1" />
    </linearGradient>

    <g id="visibility">
      <rect
          class="base-style generic-style"
          style="stroke-width:0.5;-inkscape-stroke:none;stroke:#333333;fill:#ccdddd;stroke-opacity:0.25"
          width="12"
          height="8"
          x="1"
          y="1"
          ry="2.5" />
      <path
          class="base-style generic-style"
          style="stroke-width:1;stroke:#333333;fill:none"
          d="m 3,5.375 c 3,2 5,2 8,0 -3,-3 -5,-3 -8,0 z" />
      <circle
          class="base-style generic-style"
          style="stroke-width:0.5;stroke:none;fill:#333333"
          cx="7"
          cy="4.875"
          r="2" />
      <circle
          class="base-style generic-style"
          style="stroke-width:0.5;stroke:none;fill:url(#visibilityGrad)"
          cx="7"
          cy="4.875"
          r="0.8" />
    </g>

    <xsl:apply-templates />
  </xsl:template>

  <!-- / DEFS -->



  <!-- INKSCAPE -->
  <!-- ######## -->

  <xsl:template match="sv:namedview">
    <sodipodi:namedview
        id="main_namedview"
        pagecolor="#ffffff"
        bordercolor="#666666"
        borderopacity="1.0"
        inkscape:showpageshadow="2"
        inkscape:pageopacity="0.0"
        inkscape:pagecheckerboard="0"
        inkscape:deskcolor="#d1d1d1"
        showgrid="true"
        showguides="false">
      <inkscape:grid
          type="xygrid"
          id="main_grid"
          empspacing="8"
          originx="4"
          originy="4"
          spacingy="1"
          spacingx="1"
          units="px"
          visible="true" />
      <sodipodi:guide
          position="0,508"
          orientation="0,-1"
          id="guide1"
          inkscape:locked="false" />
      <sodipodi:guide
          position="4,508"
          orientation="1,0"
          id="guide2"
          inkscape:locked="false" />
    </sodipodi:namedview>
  </xsl:template>

  <!-- / INKSCAPE -->

</xsl:stylesheet>
