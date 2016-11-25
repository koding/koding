module.exports = (options, callback) ->

  { account } = options
  userAccount   = JSON.stringify account

  addSiteScripts = require './sitescripts'
  addSiteTags    = require './sitetags'

  prepareHTML = (site) ->
    """
    <!doctype html>
    <html lang="en">
    <head>

      #{addSiteTags site}

      <link rel="shortcut icon" href="/a/images/favicon.ico" />
      <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
      <link href="https://plus.google.com/+KodingInc" rel="publisher" />
      <link href='https://chrome.google.com/webstore/detail/koding/fgbjpbdfegnodokpoejnbhnblcojccal' rel='chrome-webstore-item'>

      <link rel="stylesheet" href="/a/site.#{site}/css/main.css?#{KONFIG.version}" />

    </head>

    <body class='home'>
      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      <script>
        window._runtimeOptions = {
          google    : #{JSON.stringify KONFIG.client.runtimeOptions.google},
          gitlab    : #{JSON.stringify KONFIG.client.runtimeOptions.gitlab},
          recaptcha : #{JSON.stringify KONFIG.client.runtimeOptions.recaptcha},
          domains   : #{JSON.stringify KONFIG.client.runtimeOptions.domains},
          stripe    : #{JSON.stringify KONFIG.client.runtimeOptions.stripe}
        }
      </script>


      <script src="/a/site.#{site}/js/libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{site}/js/main.js?#{KONFIG.version}"></script>

      #{addSiteScripts site}

    </body>
    </html>
    """

  return callback null, prepareHTML 'landing'
