module.exports = (options, callback) ->

  getTitle = require './../title'

  { campaign, account, bongoModels } = options
  campaign or= 'landing'

  userAccount   = JSON.stringify account
  campaignStats = null

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

      <!-- SEGMENT.IO -->
      <script type="text/javascript">
        !function(){var analytics=window.analytics=window.analytics||[];if(!analytics.initialize)if(analytics.invoked)window.console&&console.error&&console.error("Segment snippet included twice.");else{analytics.invoked=!0;analytics.methods=["trackSubmit","trackClick","trackLink","trackForm","pageview","identify","group","track","ready","alias","page","once","off","on"];analytics.factory=function(t){return function(){var e=Array.prototype.slice.call(arguments);e.unshift(t);analytics.push(e);return analytics}};for(var t=0;t<analytics.methods.length;t++){var e=analytics.methods[t];analytics[e]=analytics.factory(e)}analytics.load=function(t){var e=document.createElement("script");e.type="text/javascript";e.async=!0;e.src=("https:"===document.location.protocol?"https://":"http://")+"cdn.segment.com/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(e,n)};analytics.SNIPPET_VERSION="3.0.1";
          analytics.load("#{KONFIG.segment}");
        }}();
      </script>

      <script>
        window._runtimeOptions = {
          google    : #{JSON.stringify KONFIG.client.runtimeOptions.google},
          gitlab    : #{JSON.stringify KONFIG.client.runtimeOptions.gitlab},
          recaptcha : #{JSON.stringify KONFIG.client.runtimeOptions.recaptcha},
          domains   : #{JSON.stringify KONFIG.client.runtimeOptions.domains}
        }
      </script>

      #{addSiteScripts site}

      <script src="/a/site.#{site}/js/libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{site}/js/main.js?#{KONFIG.version}"></script>
    </body>
    </html>
    """

  switch campaign
    when 'hackathon'
      bongoModels.JWFGH.getStats account, (err, stats) ->

        return callback null, prepareHTML 'landing'  if err

        campaignStats = JSON.stringify stats
        return callback null, prepareHTML 'hackathon'

    else
      return callback null, prepareHTML 'landing'
