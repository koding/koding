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
    <script>
      window._runtimeOptions = {
        google    : {{.Runtime.Google}},
        recaptcha : {{.Runtime.Recaptcha}}
      };
    </script>

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

    <script>
      (function(h,o,t,j,a,r){
        h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
        h._hjSettings={hjid:156048,hjsv:5};
        a=o.getElementsByTagName('head')[0];
        r=o.createElement('script');r.async=1;
        r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
        a.appendChild(r);
      })(window,document,'//static.hotjar.com/c/hotjar-','.js?sv=');
    </script>

    <a href='/Activity/Public' class="invisible" target='_self'>ACTIVITY</a>

    <script type="text/javascript">
      var _hsq = window._hsq = window._hsq || [];
      (function(d,s,i,r) {
        if (d.getElementById(i)){return;}
          var n=d.createElement(s),e=d.getElementsByTagName(s)[0];
          n.id=i;n.src='//js.hs-analytics.net/analytics/'+(Math.ceil(new Date()/r)*r)+'/1593820.js';
          e.parentNode.insertBefore(n, e);
      })(document,"script","hs-analytics",300000);
    </script>
  </body>
</html>
`
