module.exports = ({account, client, bongoModels}, callback)->

  getStyles       = require './../styleblock'
  fetchScripts    = require './../scriptblock'
  getInnerNav     = require './../innernav'
  getSidebar      = require './sidebar'
  getStatusWidget = require './statuswidget'


  prepareHTML = (scripts)->
    """
    <!doctype html>
    <html lang="en">
    <head>
      <title>Koding</title>
      #{getStyles()}
    </head>
    <body>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
      #{scripts}

    </body>
    </html>
    """

  fetchScripts {bongoModels, client, intro : no}, (err, scripts)->
    callback null, prepareHTML scripts


