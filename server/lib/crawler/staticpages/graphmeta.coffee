
{argv} = require 'optimist'
{client:{version}} = require('koding-config-manager').load("main.#{argv.c}")

module.exports = ->

  """
  <meta charset="utf-8">

  <meta name="title" content="Koding - A new way for developers to work.">
  <meta name="description" content="Koding is a developer community and cloud development environment where developers come together and code in the browser.">
  <meta name="keywords" content="online IDE, collaborative IDE, online code editor, web based php editor, browser-based terminal, free virtual machine, online java IDE, coffeescript, nodejs, golang">
  <meta name="author" content="Koding">
  <meta name="fragment" content="!">
  <meta property="og:site_name" content="Koding"/>
  <meta property="og:description" content="Koding is a developer community and cloud development environment where developers come together and code in the browser."/>
  <meta property="og:title" content="Koding - A new way for developers to work."/>
  <meta property="og:url" content="https://koding.com"/>
  <meta property="og:image" content="http://koding.com/a/images/koding_share.jpg"/>
  <meta property="og:image:secure_url" content="https://koding.com/a/images/kd-fluid-icon512.png"/>
  <meta property="og:image:type" content="JPG">
  <meta property="og:image:width" content="160">
  <meta property="og:image:height" content="160">

  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Koding">
  <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1">

  <link rel="shortcut icon" href="/a/images/favicon.ico">
  <link rel="fluid-icon" href="/a/images/kd-fluid-icon512.png" title="Koding">
  <link rel="stylesheet" href="/a/css/kd.#{version}.css">
  <link rel="stylesheet" href="/a/css/introapp.#{version}.css">
  <link rel="stylesheet" href="/a/css/koding.#{version}.css">
  <link class="internal-style-app-social" rel="stylesheet" href="/a/css/__social.#{version}.css">

  """
