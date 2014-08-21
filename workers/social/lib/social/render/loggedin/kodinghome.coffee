module.exports = (options, callback)->
  {account, client, bongoModels} = options
  getStyles       = require './../styleblock'
  fetchScripts    = require './../scriptblock'
  getInnerNav     = require './../innernav'
  getTitle        = require './../title'

  entryPoint         = { slug : "koding", type: "group" }
  options.entryPoint = entryPoint

  prepareHTML = (scripts)->
    """
    <!doctype html>
    <html lang="en">
    <head>
      #{getTitle()}
      #{getStyles()}
    </head>
    <body class='logged-in'>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      #{KONFIG.getConfigScriptTag { entryPoint, roles: ['member'], permissions: [] } }
      <script>KD.isLoggedInOnLoad=true;</script>
      #{scripts}

    </body>
    </html>
    """

  fetchScripts options, (err, scripts)->
    callback null, prepareHTML scripts


