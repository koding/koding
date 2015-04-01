package templates

var LoggedInHome = `
<!doctype html>
  <html lang="en">
  <head>
    {{template "header" . }}

    <link rel="stylesheet" href="/a/p/p/{{.Version}}/kd.css" />
    <link rel="stylesheet" href="/a/p/p/{{.Version}}/app.css" />
  </head>

  <body class='logged-in dark ide'>
    <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

    <script>
      var _globals = {
        config: {{.Runtime}},
        isLoggedInOnLoad: true,
        userId: {{.User.GetWithDefaultStr "UserId" }},
        userAccount: {{.User.GetWithDefaultHash "Account"  }},
        currentGroup: {{.User.GetWithDefaultHash "Group" }},
        userEnvironmentData: {{.User.GetWithDefaultHash "EnvData" }},
        socialApiData: {{.User.GetWithDefaultHash "SocialApiData" }}
      };
    </script>

    <script src="/a/p/p/{{.Version}}/thirdparty/pubnub.min.js"></script>
    <script src="/a/p/p/{{.Version}}/bundle.js"></script>
    <script>require('app')();</script>

    <script>
      (function(d) {
        var config = {
          kitId: 'rbd0tum',
          scriptTimeout: 3000
        },
        h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
      })(document);
    </script>

    {{template "analytics" }}

    {{if not .Impersonating }}
      <script type="text/javascript">
        (function () {
        var _user_id = '{{.User.GetWithDefaultStr "Username" }}'; var _session_id = '{{.User.GetWithDefaultStr "SessionId" }}'; var _sift = _sift || []; _sift.push(['_setAccount', 'f270274999']); _sift.push(['_setUserId', _user_id]); _sift.push(['_setSessionId', _session_id]); _sift.push(['_trackPageview']); (function() { function ls() { var e = document.createElement('script'); e.type = 'text/javascript'; e.async = true; e.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'cdn.siftscience.com/s.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(e, s); } if (window.attachEvent) { window.attachEvent('onload', ls); } else { window.addEventListener('load', ls, false); } })();
        })();
      </script>
    {{end}}
</body>
</html>
`
