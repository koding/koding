package templates

var LoggedInHome = `
<!doctype html>
  <html lang="en">
  <head>
    {{template "header" . }}

    <link rel="stylesheet" href="/a/css/kd.css?{{.Version}}" />
    <link rel="stylesheet" href="/a/css/koding.css?{{.Version}}" />
  </head>

  <body class='logged-in'>
    <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

    <script>var KD={}</script>
    <script>var KD={"config":{{.Runtime}}}</script>

    <script>KD.isLoggedInOnLoad=true;</script>

    {{if .User.Exists "Account" }}
    <script>KD.userAccount={{.User.GetOnlyValue "Account"}};</script>
    {{else}}
    <script>KD.userAccount={};</script>
    {{end}}

    {{if .User.Exists "Machines" }}
    <script>KD.userMachines={{.User.GetOnlyValue "Machines"}};</script>
    {{else}}
    <script>KD.userMachines=[];</script>
    {{end}}

    {{if .User.Exists "Workspaces" }}
    <script>KD.userWorkspaces={{.User.GetOnlyValue "Workspaces"}};</script>
    {{else}}
    <script>KD.userWorkspaces=[];</script>
    {{end}}

    {{if .User.Exists "Group" }}
    <script>KD.currentGroup={{.User.GetOnlyValue "Group"}};</script>
    {{else}}
    <script>KD.currentGroup={};</script>
    {{end}}

    <script>
      (function(d) {
        var config = {
          kitId: 'rbd0tum',
          scriptTimeout: 3000
        },
        h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
      })(document);
    </script>

		{{if .User.Exists "SocialApiData" }}
    <script>KD.socialApiData={{.User.GetOnlyValue "SocialApiData"}};</script>
    {{else}}
    <script>KD.socialApiData=null;</script>
    {{end}}

    <script src='/a/js/kd.libs.js?{{.Version}}'></script>
    <script src='/a/js/kd.js?{{.Version}}'></script>
    <script src='/a/js/koding.js?{{.Version}}'></script>

    <script>
      KD.utils.defer(function () {
        KD.currentGroup = KD.remote.revive(KD.currentGroup);
        KD.userAccount = KD.remote.revive(KD.userAccount);
      });
    </script>

    {{template "analytics" }}

    {{if not .Impersonating }}
    <script type="text/javascript">
      var _user_id = '{{.User.GetOnlyValue "Username"}}'; var _session_id = '{{.User.GetOnlyValue "SessionId"}}'; var _sift = _sift || []; _sift.push(['_setAccount', 'f270274999']); _sift.push(['_setUserId', _user_id]); _sift.push(['_setSessionId', _session_id]); _sift.push(['_trackPageview']); (function() { function ls() { var e = document.createElement('script'); e.type = 'text/javascript'; e.async = true; e.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'cdn.siftscience.com/s.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(e, s); } if (window.attachEvent) { window.attachEvent('onload', ls); } else { window.addEventListener('load', ls, false); } })();
    </script>
    {{end}}
</body>
</html>
`
