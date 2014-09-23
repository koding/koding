module.exports = (siteName) ->

    # <script src="//use.typekit.net/rbd0tum.js"></script>
    # <script>try{Typekit.load();}catch(e){}</script>
  """
  <!doctype html>
  <html>
  <head>
    <title>Koding</title>
    <link rel="stylesheet" type="text/css" href="/a/site.#{siteName}/css/kd.css">
    <link rel="stylesheet" type="text/css" href="/a/site.#{siteName}/css/main.css">
  </head>
  <body class='home'>
    <script src="/a/site.#{siteName}/js/pistachio.js"></script>
    <script src="/a/site.#{siteName}/js/kd.libs.js"></script>
    <script src="/a/site.#{siteName}/js/kd.js"></script>
    <script>KD.siteName="#{siteName}";</script>
    <script src="/a/site.#{siteName}/js/main.js"></script>
  </body>
  </html>
  """