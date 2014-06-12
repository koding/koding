module.exports = (options={})->
  options.logo or= "/a/images/favicon.ico"
  """
  <meta charset="utf-8"/>
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Koding" />
  <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />
  <link rel="shortcut icon" href="#{options.logo}" />
  <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
  <link rel="stylesheet" href="/a/css/kd.css?#{KONFIG.version}" />
  <link rel="stylesheet" href="/a/css/koding.css?#{KONFIG.version}" />
  """
