KONFIG = require 'koding-config-manager'
{ version, environment, client } = KONFIG
{ runtimeOptions } = client

module.exports = (options, callback) ->

  { account } = options
  userAccount = JSON.stringify account
  addSiteScripts = require './sitescripts'

  prepareHTML = ->
    """
    <!doctype html>
    <html lang="en">
    <head>

      <meta charset="utf-8"/>

      #{require './sitetags'}

      <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
      <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />
      <link href="https://plus.google.com/+KodingInc" rel="publisher" />

      <link rel="stylesheet" href="/a/site.landing/css/main.css?#{version}" />

    </head>

    <body class='home'>
      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      <script>
        window._runtimeOptions = {
          google    : #{JSON.stringify runtimeOptions.google},
          gitlab    : #{JSON.stringify runtimeOptions.gitlab},
          recaptcha : #{JSON.stringify runtimeOptions.recaptcha},
          domains   : #{JSON.stringify runtimeOptions.domains},
          stripe    : #{JSON.stringify runtimeOptions.stripe},
          environment : #{JSON.stringify environment}
        }
      </script>


      <script src="/a/site.landing/js/libs.js?#{version}"></script>
      <script src="/a/site.landing/js/main.js?#{version}"></script>

      #{addSiteScripts()}

    </body>
    </html>
    """

  return callback null, prepareHTML()
