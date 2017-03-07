module.exports = (options, callback) ->
  { account, client, bongoModels, models } = options
  getStyles    = require './../styleblock'
  fetchScripts = require './../scriptblock'
  getTitle     = require './../title'
  KONFIG       = require 'koding-config-manager'

  options.entryPoint = { slug : 'koding', type: 'group' }

  prepareHTML = (scripts) ->

    """
    <!doctype html>
    <html lang="en">
    <head>
      #{getStyles()}
    </head>
    <body class='logged-in'>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      #{scripts}

    </body>
    </html>
    """

  fetchScripts options, (err, scripts) ->
    callback null, prepareHTML scripts
