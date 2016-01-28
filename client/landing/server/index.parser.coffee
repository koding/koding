TYPEKITIDS =
  hackathon : 'ndd8msy'

module.exports = (siteName) ->

  typeKitID= TYPEKITIDS[siteName] or 'rbd0tum'

  """
  <!doctype html>
  <html>
  <head>
    <title>Koding</title>
    <link rel="stylesheet" type="text/css" href="/a/site.#{siteName}/css/kd.css">
    <link rel="stylesheet" type="text/css" href="/a/site.#{siteName}/css/main.css">
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=false">
    <script>
      (function(d) {
        var config = {
          kitId: '#{typeKitID}',
          scriptTimeout: 3000
        },
        h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
      })(document);
    </script>

    <script type="text/javascript">
      !function(){var analytics=window.analytics=window.analytics||[];if(!analytics.initialize)if(analytics.invoked)window.console&&console.error&&console.error("Segment snippet included twice.");else{analytics.invoked=!0;analytics.methods=["trackSubmit","trackClick","trackLink","trackForm","pageview","identify","group","track","ready","alias","page","once","off","on"];analytics.factory=function(t){return function(){var e=Array.prototype.slice.call(arguments);e.unshift(t);analytics.push(e);return analytics}};for(var t=0;t<analytics.methods.length;t++){var e=analytics.methods[t];analytics[e]=analytics.factory(e)}analytics.load=function(t){var e=document.createElement("script");e.type="text/javascript";e.async=!0;e.src=("https:"===document.location.protocol?"https://":"http://")+"cdn.segment.com/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(e,n)};analytics.SNIPPET_VERSION="3.0.1";
        analytics.load("kb2hfdgf20");
      }}();
    </script>
  </head>
  <body class='home'>
    <script src="/a/site.#{siteName}/js/libs.js"></script>
    <script src="/a/site.#{siteName}/js/kd.libs.js"></script>
    <script src="/a/site.#{siteName}/js/kd.js"></script>
    <script>KD.siteName="#{siteName}";</script>
    <script src="/a/site.#{siteName}/js/main.js"></script>
  </body>
  </html>
  """
