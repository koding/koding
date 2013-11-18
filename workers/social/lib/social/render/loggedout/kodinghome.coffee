module.exports = ({account, client, bongoModels}, callback)->

  getStyles    = require './../styleblock'
  fetchScripts = require './../scriptblock'
  getGraphMeta = require './../graphmeta'

  prepareHTML = (scripts)->
    """

    <!doctype html>
    <html lang="en" prefix="og: http://ogp.me/ns#">
    <head>
      <title>Koding</title>
      #{getStyles()}
      #{getGraphMeta()}
    </head>
    <body class='koding intro'>

      <!--[if IE]>
      <script>(function(){window.location.href='/unsupported.html'})();</script>
      <![endif]-->

      <div class="kdview home" id="kdmaincontainer">
        <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
        <header class="kdview" id='main-header'>
          <div class="kdview">
            <a id="koding-logo" href="#" class='large'><span></span></a>
            <a id="header-sign-in" class="custom-link-view login" href="#!/Login"><span class="title" data-paths="title">Login</span></a>
          </div>
        </header>
      </div>

      #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
      #{scripts}

    </body>
    </html>
    """


  fetchScripts {bongoModels, client, intro : yes}, (err, scripts)->
    callback null, prepareHTML scripts

