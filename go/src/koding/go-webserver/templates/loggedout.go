package templates

var LoggedOutHome = `
<!doctype html>
  <html lang="en">
  <head>
    {{template "header" . }}
    <meta name="fragment" content="!">

    <link rel="stylesheet" href="/a/site.landing/css/kd.css?{{.Version}}" />
    <link rel="stylesheet" href="/a/site.landing/css/main.css?{{.Version}}" />
  </head>

  <body class='home'>
    {{template "analytics"}}

    <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->
    <script src="/a/site.landing/js/libs.js?{{.Version}}"></script>
    <script src="/a/site.landing/js/kd.libs.js?{{.Version}}"></script>
    <script src="/a/site.landing/js/kd.js?{{.Version}}"></script>
    <script src="/a/site.landing/js/main.js?{{.Version}}"></script>

    <script>
      (function(d) {
        var config = {
          kitId: 'rbd0tum',
          scriptTimeout: 3000
        },
        h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
      })(document);
    </script>

    <a href='/Activity/Public' class="invisible" target='_self'>ACTIVITY</a>
  </body>
</html>
`
