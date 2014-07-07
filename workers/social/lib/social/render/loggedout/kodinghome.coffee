module.exports = (options, callback)->
  {account, client, bongoModels} = options
  getStyles    = require './../styleblock'
  fetchScripts = require './../scriptblock'
  getGraphMeta = require './../graphmeta'

  entryPoint         = { slug : "koding", type: "group" }
  options.entryPoint = entryPoint

  prepareHTML = (scripts)->
    """
    <!doctype html>
    <html lang="en" prefix="og: http://ogp.me/ns#">
    <head>
      <title>Koding | A New Way For Developers To Work</title>
      #{getStyles()}
      #{getGraphMeta()}
    </head>
    <body>
      <!--[if IE]>
      <script>(function(){window.location.href='/unsupported.html'})();</script>
      <![endif]-->
      #{KONFIG.getConfigScriptTag { entryPoint, roles: ['guest'], permissions: [] } }
      <script>KD.isLoggedInOnLoad=false;</script>
      #{scripts}
    </body>
    </html>
    """


  fetchScripts options, (err, scripts)->
    callback null, prepareHTML scripts

