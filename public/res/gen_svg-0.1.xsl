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
  <xsl:variable name="primfontW" select="5" />
  <xsl:variable name="primfontH" select="$primfontW*2" />
  <xsl:variable name="totalwidth" select="24" />
  <xsl:variable name="layerContentX" select="$unitsize * 1.5" />
  <xsl:variable name="layerContentY" select="$unitsize * 3.5" />

  <!-- All template application is explicit. -->
  <xsl:template match="node()" />
  <xsl:template match="node()" mode="autodefs" />
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

  <xsl:template match="sv:taglist" mode="required_width">
    <xsl:param name="index" select="count(sv:tag)" />
    <xsl:param name="current_sum" select="0" />
    <xsl:variable name="tagid" select="sv:tag[$index]/@name" />
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:apply-templates select="." mode="required_width">
          <xsl:with-param name="index" select="$index - 1" />
          <xsl:with-param
              name="current_sum"
              select="$current_sum + key('find_tag', $tagid)/@width + 2" />
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
    <xsl:variable name="prim_w" select="string-length(@name)*$primfontW" />
    <xsl:variable name="tag_w">
      <xsl:apply-templates select="." mode="contents_width" />
    </xsl:variable>
    <xsl:variable name="max_row">
      <xsl:call-template name="get_max">
        <xsl:with-param name="a" select="$prim_w" />
        <xsl:with-param name="b" select="$tag_w" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$max_row + sum(@indent)*$indentFactor*$unitsize" />
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
    <xsl:variable name="following_indent" select="sum(following-sibling::sv:prim[1]/@indent)" />
    <xsl:variable name="last_prim" select="not(following-sibling::sv:prim)" />
    <xsl:variable name="required_vline">
      <xsl:apply-templates select="." mode="required_prim_vline" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="(sum(@indent) &lt; $following_indent) or $last_prim">
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
    <xsl:param name="parent" />
    <xsl:param name="gridX" select="0" />
    <xsl:param name="gridY" select="0" />
    <xsl:variable name="width">
      <xsl:apply-templates select="." mode="required_width" />
    </xsl:variable>
    <xsl:variable name="id" select="@id" />
    <xsl:for-each select="descendant::sv:tag[@target]">
      <xsl:variable name="preceding_vspan">
        <xsl:apply-templates select="../../.." mode="contents_height">
          <xsl:with-param name="index" select="count(../../preceding-sibling::sv:prim)" />
        </xsl:apply-templates>
      </xsl:variable>
      <xsl:apply-templates select="//sv:stack[@id = current()/@target]">
        <xsl:with-param name="gridX" select="$gridX + sum(../../@indent)*$indentFactor" />
        <xsl:with-param name="gridY" select="$gridY + $preceding_vspan" />
        <xsl:with-param name="parent" select="$id" />
      </xsl:apply-templates>
    </xsl:for-each>
    <g id="{concat('stack_', @id)}"
       data-gridX="{$gridX}"
       data-gridY="{$gridY}"
       data-width="{$width}">
      <xsl:if test="$parent">
        <xsl:attribute name="data-parent">
          <xsl:value-of select="concat('stack_', $parent)" />
        </xsl:attribute>
      </xsl:if>
      <xsl:attribute name="inkscape:groupmode">layer</xsl:attribute>
      <xsl:apply-templates>
        <xsl:with-param name="stackX" select="$gridX" />
        <xsl:with-param name="stackY" select="$gridY" />
        <xsl:with-param name="w" select="$width" />
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
    <g id="{concat('layer_', ../@id, '_', @idSuffix)}">
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
  <!-- <sv:prim isa="xform" name="x" barSkip="1" barDraw="1" default="1" height="4" /> -->

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

  <xsl:template name="prim_transform">
    <xsl:attribute name="transform">
      <xsl:call-template name="generate_prim_specific_transform">
        <xsl:with-param name="offsetX" select="sum(@indent)*$indentFactor*$unitsize" />
      </xsl:call-template>
    </xsl:attribute>
  </xsl:template>

  <xsl:template name="prim_name">
    <text class="prim-name-string" x="18.5" y="30.75">
      <xsl:value-of select="@name" />
    </text>
  </xsl:template>

  <xsl:template match="sv:prim">
    <xsl:variable name="spec">
      <xsl:choose>
        <xsl:when test="@spec"><xsl:value-of select="@spec" /></xsl:when>
        <xsl:otherwise>def</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="treat_as_default"
                  select="@default and preceding::sv:layer" />
    <xsl:if test="$treat_as_default">
      <g inkscape:label="defaultprim" class="expanded-modes">
        <xsl:call-template name="prim_transform" />
        <xsl:call-template name="prim_name" />
      </g>
    </xsl:if>
    <g class="content" inkscape:label="{concat('prim-',@name)}">
      <xsl:call-template name="prim_transform" />
      <xsl:if test="not($treat_as_default)">
        <xsl:call-template name="prim_name" />
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
                      ' h ', $unitsize*$indentFactor - 2,
                      ' m ', '2, 2',
                      ' v ', $vline * $unitsize - 1.5
                      )" />
        </xsl:attribute>
        <xsl:attribute name="style">
          <xsl:choose>
            <xsl:when test="$spec = 'def'">
              <xsl:value-of select="'stroke-dasharray:none'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'stroke-dasharray:2, 2'" />
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
    <xsl:param name="index" select="count(preceding-sibling::sv:tag)" />
    <xsl:param name="offset" select="0" />
    <xsl:choose>
      <xsl:when test="$index">
        <xsl:variable name="tagid" select="../sv:tag[$index]/@name" />
        <xsl:variable name="total" select="$offset + key('find_tag', $tagid)/@width" />
        <xsl:call-template name="tag_loop">
          <xsl:with-param name="index" select="$index - 1" />
          <xsl:with-param name="offset" select="$total + 2" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$offset" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Example: -->
  <!-- <sv:taglist> -->
  <!--   <sv:tag name="custom-data" empty="1" /> -->
  <!--   <sv:tag name="asset-info" /> -->
  <!-- </sv:taglist> -->

  <xsl:template match="sv:taglist">
    <xsl:apply-templates>
      <xsl:with-param name="row_index"
                      select="count(preceding-sibling::sv:taglist)" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="sv:tag">
    <xsl:param name="row_index" />
    <xsl:variable name="placeholder">
      <xsl:if test="@empty">-placeholder</xsl:if>
    </xsl:variable>
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
    <use href="#tag{$placeholder}-{@name}" transform="{$transform}">
      <xsl:call-template name="write_info" />
    </use>
  </xsl:template>

  <!-- / LAYER CONTENTS -->



  <!-- DEFS -->
  <!-- #### -->

  <xsl:template match="sv:deftag">
    <g id="tag-{@id}">
      <xsl:call-template name="write_info" />
      <rect
          class="base-style prim-tag"
          style="fill:{@color}"
          width="{@width}"
          height="6"
          ry="1" />
      <xsl:call-template name="tag_string">
        <xsl:with-param name="value" select="@value" />
      </xsl:call-template>
    </g>

    <g id="tag-placeholder-{@id}">
      <rect
          class="base-style prim-tag-placeholder"
          width="{@width}"
          height="6"
          ry="1" />
    </g>
  </xsl:template>

  <xsl:template name="tag_string">
    <xsl:param name="value" />
    <text class="prim-tag-string" x="1.5" y="5">
      <xsl:value-of select="$value" />
    </text>
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
        <xsl:call-template name="tag_string">
          <xsl:with-param name="value" select="translate(@isa,
                                               'abcdefghijklmnopqrstuvwxyz',
                                               'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
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

      .prim-tag-placeholder
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
      stroke:#000000;
      fill-opacity:1;
      stroke-width:1;
      stroke-linecap:round;
      stroke-linejoin:round;
      stroke-dasharray:none;
      stroke-opacity:1;
      stop-color:#000000;
      }

      .spec-pline
      {
      fill:none;
      stroke:#000000;
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
        r="2" />

    <circle
        id="spec-dot-class"
        class="spec-dot"
        style="fill:#88CC99"
        r="2" />

    <circle
        id="spec-dot-over"
        class="spec-dot"
        style="fill:none"
        r="2" />

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
