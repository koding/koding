package templates

var LoggedInHome = `
<!doctype html>
  <html lang="en">
  <head>
    <title>Koding | A New Way For Developers To Work</title>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <meta name="apple-mobile-web-app-title" content="Koding" />
    <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />
    <link rel="shortcut icon" href="/a/images/favicon.ico" />
    <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />

    <link rel="stylesheet" href="/a/css/kd.css?%s" />
    <link rel="stylesheet" href="/a/css/koding.css?%s" />
  </head>

  <body class='logged-in'>
  <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

  <script>var KD={}</script>
  <script>var KD={"config":%s}</script>

  <script>KD.isLoggedInOnLoad=%v;</script>
  <script>KD.config.usePremiumBroker=%v;</script>

  <script>KD.userAccount=%s;</script>
  <script>KD.userMachines=%s;</script>
  <script>KD.userWorkspaces=%s;</script>
  <script>KD.currentGroup=%s;</script>

  <script src='/a/js/kd.libs.js?%s'></script>
  <script src='/a/js/kd.js?%s'></script>
  <script src='/a/js/koding.js?%s'></script>

  <script>
    KD.utils.defer(function () {
      KD.currentGroup = KD.remote.revive(KD.currentGroup);
      KD.userAccount = KD.remote.revive(KD.userAccount);
    });
  </script>

  <script type="text/javascript">
    window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
    window.analytics.load("4c570qjqo0");
    window.analytics.page();
  </script>
  <script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

    ga('create', 'UA-6520910-8', 'auto');
  </script>
</body>
</html>
`
