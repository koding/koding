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

  entryPoint = { slug : slug, type: "group" }
  options.entryPoint = entryPoint

  prepareHTML = (scripts)->
    """

    <!DOCTYPE html>
    <html>
    <head>
      <title>#{encoder.XSSEncode title}</title>
      #{getStyles customize}
    </head>
    <body class="group logged-in">

    <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

    #{KONFIG.getConfigScriptTag {entryPoint, roles:['guest'], permissions:[]}}
    #{scripts}
    </body>
    </html>

    """

  fetchScripts options, (err, scripts)->
    callback null, prepareHTML scripts
