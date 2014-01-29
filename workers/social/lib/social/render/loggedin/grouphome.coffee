module.exports = (options, callback)->

  getStyles    = require './../styleblock'
  fetchScripts = require './../scriptblock'
  getSidebar   = require './sidebar'
  encoder      = require 'htmlencode'

  {
    account, slug, title, content, body,
    avatar, counts, policy, customize,
    bongoModels, client
  } = options

  prepareHTML = (scripts)->
    """

    <!DOCTYPE html>
    <html>
    <head>
      <title>#{encoder.XSSEncode title}</title>
      #{getStyles()}
    </head>
    <body class="group">

    <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

    #{KONFIG.getConfigScriptTag {entryPoint: { slug : slug, type: "group"}, roles:['guest'], permissions:[]}}
    #{scripts}
    </body>
    </html>

    """

  fetchScripts {bongoModels, client, slug}, (err, scripts)->
    callback null, prepareHTML scripts
