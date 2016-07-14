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
        gitlab    : {{.Runtime.Gitlab}},
        recaptcha : {{.Runtime.Recaptcha}},
        domains   : {{.Runtime.Domains}}
      };
    </script>

    {{.UnsupportedHTML}}
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
  </body>
</html>
`
