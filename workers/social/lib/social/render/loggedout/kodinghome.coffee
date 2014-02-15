module.exports = (options, callback)->
  {account, client, bongoModels} = options
  getStyles    = require './../styleblock'
  fetchScripts = require './../scriptblock'
  getGraphMeta = require './../graphmeta'

  prepareHTML = (scripts)->
    """

    <!doctype html>
    <html lang="en" prefix="og: http://ogp.me/ns#">
    <head>
      <title>Koding | A new way for developers to work.</title>
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
            <a class="custom-link-view login header-sign-in" href="#!/Login"><span class="title" data-paths="title">Login</span></a>
          </div>
        </header>
      </div>

      #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
      #{scripts}

    </body>
    </html>
    """


  options.intro = yes
  fetchScripts options, (err, scripts)->
    callback null, prepareHTML scripts

