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

  <script>KD.userAccount={{.User.Account}};</script>
  <script>KD.userMachines={{.User.Machines}};</script>
  <script>KD.userWorkspaces={{.User.Workspaces}};</script>
  <script>KD.currentGroup={{.User.Group}};</script>
  <script>KD.socialApiData={{.User.SocialApiData}};</script>

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
      var _user_id = '{{.User.Username}}'; var _session_id = '{{.User.SessionId}}'; var _sift = _sift || []; _sift.push(['_setAccount', 'f270274999']); _sift.push(['_setUserId', _user_id]); _sift.push(['_setSessionId', _session_id]); _sift.push(['_trackPageview']); (function() { function ls() { var e = document.createElement('script'); e.type = 'text/javascript'; e.async = true; e.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'cdn.siftscience.com/s.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(e, s); } if (window.attachEvent) { window.attachEvent('onload', ls); } else { window.addEventListener('load', ls, false); } })();
    </script>
  {{end}}
</body>
</html>
`
