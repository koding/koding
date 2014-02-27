module.exports = ({client, bongoModels, page}, callback)->

  getStyles    = require './styleblock'
  fetchScripts = require './scriptblock'
  getGraphMeta = require './graphmeta'

  getBody  = (scripts) ->
    """

    <!doctype html>
    <html lang="en" prefix="og: http://ogp.me/ns#">
    <head>
      <title>Koding | A New Way For Developers To Work</title>
      #{getStyles()}
      <link rel="stylesheet" href="/a/css/landingapp.#{KONFIG.version}.css" />
      <link href="https://fonts.googleapis.com/css?family=Raleway:100,700" rel="stylesheet" type="text/css">
      #{getGraphMeta()}
    </head>
    <body class='koding landing'>
      <!--[if IE]>
      <script>(function(){window.location.href='/unsupported.html'})();</script>
      <![endif]-->
      <div class="kdview home" id="kdmaincontainer"></div>
      #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
      #{scripts}
    </body>
    </html>
    """

  fetchScripts {bongoModels, client, landing: page}, (err, scripts)->
    callback null, getBody scripts
