
{argv} = require 'optimist'
{uri, client:{version}} = require('koding-config-manager').load("main.#{argv.c}")

module.exports = ->

  """
  <meta charset="utf-8">

  <meta name="msvalidate.01" content="F56689F2116FE1CC34876D855B2A5A8A" />

  <meta name="description" content="Koding is a developer community and cloud development environment where developers come together and code in the browser.">
  <meta name="author" content="Koding">
  <meta name="robots" content="noodp,noydir" />
  <meta name="fragment" content="!">

  <meta itemprop="name" content="Koding">
  <meta itemprop="description" content="Koding is a developer community and cloud development environment where developers come together and code in the browser.">
  <meta itemprop="image" content="#{uri.address}/a/images/logos/share_logo.png">

  <!-- og meta tags -->
  <meta property="og:title" content="Koding - A new way for developers to work."/>
  <meta property="og:type" content="website"/>
  <meta property="og:url" content="https://koding.com"/>
  <meta property="og:image" content="#{uri.address}/a/images/logos/share_logo.png"/>
  <meta property="og:description" content="Koding is a developer community and cloud development environment where developers come together and code in the browser."/>
  <meta property="og:image:type" content="png">
  <meta property="og:image:width" content="400"/>
  <meta property="og:image:height" content="300"/>

  <!-- twitter cards -->
  <meta name="twitter:site" content="@koding"/>
  <meta name="twitter:url" content="https://koding.com"/>
  <meta name="twitter:title" content="Koding - A new way for developers to work."/>
  <meta name="twitter:creator" content="@koding"/>
  <meta name="twitter:card" content="summary"/>
  <meta name="twitter:image" content="#{uri.address}/a/images/logos/share_logo.png"/>
  <meta name="twitter:description" content="Koding is a developer community and cloud development environment where developers come together and code in the browser."/>
  <meta name="twitter:domain" content="koding.com">


  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Koding">
  <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1">

  <link rel="shortcut icon" href="#{uri.address}/a/images/favicon.ico">
  <link rel="fluid-icon" href="#{uri.address}/a/images/logos/fluid512.png" title="Koding">
  <link rel="stylesheet" href="/a/css/kd.#{version}.css">
  <link rel="stylesheet" href="/a/css/introapp.#{version}.css">
  <link rel="stylesheet" href="/a/css/koding.#{version}.css">
  <link class="internal-style-app-social" rel="stylesheet" href="/a/css/__social.#{version}.css">

  """
