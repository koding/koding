module.exports = (options, callback)->

  getTitle = require './../title'

  {campaign, account, bongoModels} = options
  campaign or= 'landing'

  userAccount   = JSON.stringify account
  campaignStats = null

  addSiteScripts = require './sitescripts'
  addSiteTags    = require './sitetags'

  prepareHTML = (site)->
    """
    <!doctype html>
    <html lang="en">
    <head>

      #{addSiteTags site}

      <link rel="shortcut icon" href="/a/images/favicon.ico" />
      <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
      <link rel="stylesheet" href="/a/site.#{site}/css/kd.css?#{KONFIG.version}" />
      <link rel="stylesheet" href="/a/site.#{site}/css/main.css?#{KONFIG.version}" />
    </head>
    <body class='home'>
      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      <!-- SEGMENT.IO -->
      <script type="text/javascript">
        window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
        window.analytics.load("4c570qjqo0");
        window.analytics.page();
      </script>

      <script src="/a/site.#{site}/js/libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{site}/js/kd.libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{site}/js/kd.js?#{KONFIG.version}"></script>
      <script>KD.userAccount=#{userAccount}</script>
      <script>KD.campaignStats=#{campaignStats}</script>
      <script src="/a/site.#{site}/js/main.js?#{KONFIG.version}"></script>

      #{addSiteScripts site}
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



