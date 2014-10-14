module.exports = (options, callback)->

  getTitle = require './../title'

  {campaign, account, bongoModels} = options
  campaign or= 'landing'

  userAccount   = JSON.stringify account
  campaignStats = null

  prepareHTML = ->
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
      <link rel="stylesheet" href="/a/site.#{campaign}/css/kd.css?#{KONFIG.version}" />
      <link rel="stylesheet" href="/a/site.#{campaign}/css/main.css?#{KONFIG.version}" />
    </head>
    <body class='home'>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      <script src="/a/site.#{campaign}/js/pistachio.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{campaign}/js/kd.libs.js?#{KONFIG.version}"></script>
      <script src="/a/site.#{campaign}/js/kd.js?#{KONFIG.version}"></script>
      <script>KD.userAccount=#{userAccount}</script>
      <script>KD.campaignStats=#{campaignStats}</script>
      <script src="/a/site.#{campaign}/js/main.js?#{KONFIG.version}"></script>

      <!-- SEGMENT.IO -->
      <script type="text/javascript">
        window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
        window.analytics.load("4c570qjqo0");
        window.analytics.page();
      </script>

      <!-- Google Analytics -->
      <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){ (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o), m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m) })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', 'UA-6520910-8', 'auto');
        ga('send', 'pageview');
      </script>
      <script>
        (function(d) {
          var config = {
            kitId: 'rbd0tum',
            scriptTimeout: 3000
          },
          h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
        })(document);
      </script>
    </body>
    </html>
    """

  switch campaign
    when 'hackathon'
      bongoModels.JWFGH.getStats account, (err, stats) ->

        console.log err  if err

        campaignStats = JSON.stringify stats
        callback null, prepareHTML()
    else
      callback null, prepareHTML()



