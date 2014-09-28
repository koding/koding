module.exports = (options, callback)->

  getTitle = require './../title'

  prepareHTML = ->
    """
    <!doctype html>
    <html lang="en">
    <head>
      #{getTitle()}
      <meta charset="utf-8"/>
      <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
      <meta name="apple-mobile-web-app-capable" content="yes">
      <meta name="apple-mobile-web-app-status-bar-style" content="black">
      <meta name="apple-mobile-web-app-title" content="Koding" />
      <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />
      <link rel="shortcut icon" href="/a/images/favicon.ico" />
      <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
      <link rel="stylesheet" href="/a/site.landing/css/kd.css?#{KONFIG.version}" />
      <link rel="stylesheet" href="/a/site.landing/css/main.css?#{KONFIG.version}" />
    </head>
    <body class='home'>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      <script src="/a/site.landing/js/pistachio.js?#{KONFIG.version}"></script>
      <script src="/a/site.landing/js/kd.libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.landing/js/kd.js?#{KONFIG.version}"></script>
      <script src="/a/site.landing/js/main.js?#{KONFIG.version}"></script>
    </body>
    </html>
    """

  callback null, prepareHTML()


