module.exports = (options, callback)->
  {account, client, bongoModels} = options
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
      <title>Koding | A New Way For Developers To Work</title>
      #{getStyles()}
    </head>
    <body>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
      #{scripts}

    </body>
    </html>
    """

  options.intro = no
  fetchScripts options, (err, scripts)->
    callback null, prepareHTML scripts


