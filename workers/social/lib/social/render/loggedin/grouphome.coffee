module.exports = (options, callback)->

  getStyles    = require './../styleblock'
  fetchScripts = require './../scriptblock'
  getTitle     = require './../title'
  getGraphMeta = require './../graphmeta'


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
      #{getTitle()}
      #{getGraphMeta()}
      #{getStyles customize}
    </head>
    <body class="group logged-in">

    <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

    #{scripts}
    </body>
    </html>

    """

  fetchScripts options, (err, scripts)->
    callback null, prepareHTML scripts
