encoder = require 'htmlencode'

{ uri, domains, client: { version } } = require 'koding-config-manager'

module.exports = (options = {}) ->
  options.title ?= 'Modern Dev Environment Delivered · Koding'
  options.shareUrl ?= "https://#{domains.base}"
  options.image ?= "#{uri.address}/a/images/logos/share_logo.png"
  options.body ?= 'Instantly create, share, scale and manage development environments'

  """
  <meta name="keywords" content="Web IDE, Cloud VM, VM, VPS, Ruby, Node, PHP, Python, WordPress, Django, Programming, virtual machines">
  <meta charset="utf-8">

  <meta name="msvalidate.01" content="F56689F2116FE1CC34876D855B2A5A8A" />

  <meta name="description" content="#{encoder.XSSEncode options.body}">
  <meta name="author" content="Koding">
  <meta name="robots" content="noodp,noydir" />
  <meta name="fragment" content="!">

  <meta itemprop="name" content="Koding">
  <meta itemprop="description" content="#{encoder.XSSEncode options.body}">
  <meta itemprop="image" content="#{uri.address}/a/images/logos/share_logo.png">

  <!-- og meta tags -->
  <meta property="og:title" content="#{encoder.XSSEncode options.title}"/>
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
  <meta name="twitter:title" content="#{encoder.XSSEncode options.title}"/>
  <meta name="twitter:creator" content="@koding"/>
  <meta name="twitter:card" content="summary"/>
  <meta name="twitter:image" content="#{options.image}"/>
  <meta name="twitter:description" content="#{encoder.XSSEncode options.body}"/>
  <meta name="twitter:domain" content="#{domains.base}">


  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Koding">
  <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1">

  <link href='https://chrome.google.com/webstore/detail/koding/fgbjpbdfegnodokpoejnbhnblcojccal' rel='chrome-webstore-item'>

  <script>
  var _prum = [['id', '54a5cf1eabe53d1d20d455ec'],
               ['mark', 'firstbyte', (new Date()).getTime()]];
  (function() {
      var s = document.getElementsByTagName('script')[0]
        , p = document.createElement('script');
      p.async = 'async';
      p.src = '//rum-static.pingdom.net/prum.min.js';
      s.parentNode.insertBefore(p, s);
  })();
  </script>

  """
