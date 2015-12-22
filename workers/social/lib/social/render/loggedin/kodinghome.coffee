module.exports = (options, callback) ->
  { account, client, bongoModels, models } = options
  getStyles       = require './../styleblock'
  fetchScripts    = require './../scriptblock'
  getTitle        = require './../title'
  getGraphMeta    = require './../graphmeta'
  { argv }          = require 'optimist'
  { uri }           = require('koding-config-manager').load("main.#{argv.c}")

  entryPoint         = { slug : 'koding', type: 'group' }
  options.entryPoint = entryPoint

  prepareHTML = (scripts, socialApiData) ->
    if socialApiData?.navigated?
      { navigated } = socialApiData

      { slug, data } = navigated

      if message = data?.message
        { body } = message
        summary  = body.slice(0, 80)
        title    = "#{summary} | Koding Community"

      url = if uri?.address then uri.address else 'https://koding.com/'
      shareUrl = "#{url}/#{slug}"

    """
    <!doctype html>
    <html lang="en">
    <head>
      #{getTitle { title: title } }
      #{getGraphMeta { shareUrl: shareUrl, body: body }}
      #{getStyles()}
    </head>
    <body class='logged-in'>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      #{scripts}

    </body>
    </html>
    """

  fetchScripts options, (err, scripts, socialApiData) ->
    callback null, prepareHTML scripts, socialApiData


