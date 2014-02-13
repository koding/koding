{argv} = require 'optimist'
{uri, client:{version}} = require('koding-config-manager').load("main.#{argv.c}")
encoder      = require 'htmlencode'

module.exports = (options = {})->
  options.title ?= "A new way for developers to work."
  options.shareUrl ?= "https://koding.com"
  options.image ?= "#{uri.address}/a/images/koding_share_green.png"
  options.body ?= "Koding is a developer community and cloud development environment where developers come together and code in the browser."

  """
  <meta charset="utf-8">

  <meta name="msvalidate.01" content="F56689F2116FE1CC34876D855B2A5A8A" />

  <meta name="description" content="#{encoder.XSSEncode options.body}">
  <meta name="author" content="Koding">
  <meta name="robots" content="noodp,noydir" />
  <meta name="fragment" content="!">

  <meta itemprop="name" content="Koding">
  <meta itemprop="description" content="#{encoder.XSSEncode options.body}">
  <meta itemprop="image" content="#{uri.address}/a/images/koding_share_green.png">

  <!-- og meta tags -->
  <meta property="og:title" content="Koding - #{encoder.XSSEncode options.title}"/>
  <meta property="og:type" content="website"/>
  <meta property="og:url" content="#{options.shareUrl}"/>
  <meta property="og:image" content="#{options.image}"/>
  <meta property="og:image:secure_url" content="#{options.image}"/>
  <meta property="og:description" content="#{encoder.XSSEncode options.body}"/>
  <meta property="og:image:type" content="image/png">
  <meta property="og:image:width" content="400"/>
  <meta property="og:image:height" content="300"/>

  <!-- twitter cards -->
  <meta name="twitter:site" content="@koding"/>
  <meta name="twitter:url" content="#{options.shareUrl}"/>
  <meta name="twitter:title" content="Koding - #{encoder.XSSEncode options.title}"/>
  <meta name="twitter:creator" content="@koding"/>
  <meta name="twitter:card" content="summary"/>
  <meta name="twitter:image" content="#{options.image}"/>
  <meta name="twitter:description" content="#{encoder.XSSEncode options.body}"/>
  <meta name="twitter:domain" content="koding.com">


  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Koding">
  <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1">

  """
