module.exports = (options, callback)->

  getTitle = require './../title'

  {campaign, account, bongoModels} = options
  campaign or= 'landing'

  userAccount   = JSON.stringify account
  campaignStats = null

  addSiteScripts = require './sitescript'

  prepareHTML = (site)->
    """
    <!doctype html>
    <html lang="en">
    <head>
      #{getTitle()}
      <meta charset="utf-8"/>
      <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
      <meta name="apple-mobile-web-app-capable" content="yes">
      <meta name="apple-mobile-web-app-status-bar-style" content="black">
      <meta name="apple-mobile-web-app-title" content="Koding" />
      <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />
      <link rel="shortcut icon" href="/a/images/favicon.ico" />
      <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
      <link rel="stylesheet" href="/a/site.#{site}/css/kd.css?#{KONFIG.version}" />
      <link rel="stylesheet" href="/a/site.#{site}/css/main.css?#{KONFIG.version}" />
    </head>
    <body class='home'>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      <script src="/a/site.#{site}/js/libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{site}/js/kd.libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{site}/js/kd.js?#{KONFIG.version}"></script>
      <script>KD.userAccount=#{userAccount}</script>
      <script>KD.campaignStats=#{campaignStats}</script>
      <script src="/a/site.#{site}/js/main.js?#{KONFIG.version}"></script>

      <!-- SEGMENT.IO -->
      <script type="text/javascript">
        window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
        window.analytics.load("4c570qjqo0");
        window.analytics.page();
      </script>

      <!-- Google Analytics -->
      <script>
        (function(k,o,d,i,n,g){k['GoogleAnalyticsObject']=i;k[i]=k[i]||function(){
        (k[i].q=k[i].q||[]).push(arguments)},k[i].l=1*new Date();g=o.createElement(d),
        n=o.getElementsByTagName(d)[0];g.async=1;g.src='//www.google-analytics.com/analytics.js';
        n.parentNode.insertBefore(g,n)})(window,document,'script','ga');
        ga('create', 'UA-6520910-8', 'koding.com');ga('send', 'pageview');
      </script>

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



