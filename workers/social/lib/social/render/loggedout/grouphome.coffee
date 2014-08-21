module.exports = (options, callback)->
  {argv} = require 'optimist'
  {uri} = require('koding-config-manager').load("main.#{argv.c}")

  getStyles    = require './../styleblock'
  fetchScripts = require './../scriptblock'
  getGraphMeta = require './../graphmeta'
  getTitle     = require './../title'

  {
    account, slug, title, content, body,
    avatar, counts, policy, customize,
    bongoModels, client
  } = options

  if uri?.address and slug
    shareUrl = uri.address + "/" + slug
  shareUrl or= "https://koding.com"

  prepareHTML  = (scripts)->
    """

    <!DOCTYPE html>
    <html>
    <head>
      #{getTitle()}
      #{getStyles customize}
    </head>
    <body class="group">

    <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

    #{KONFIG.getConfigScriptTag {entryPoint: { slug : slug, type: "group"}, roles:['guest'], permissions:[]}}
    <script>KD.isLoggedInOnLoad=false;</script>
    #{scripts}
    </body>
    </html>

    """

  fetchScripts {bongoModels, client}, (err, scripts)->
    callback null, prepareHTML scripts
