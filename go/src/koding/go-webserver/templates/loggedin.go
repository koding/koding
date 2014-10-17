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

  <script type="text/javascript">
    var _user_id = '{{.User.Username}}'; var _session_id = '{{.User.SessionId}}'; var _sift = _sift || []; _sift.push(['_setAccount', 'f270274999']); _sift.push(['_setUserId', _user_id]); _sift.push(['_setSessionId', _session_id]); _sift.push(['_trackPageview']); (function() { function ls() { var e = document.createElement('script'); e.type = 'text/javascript'; e.async = true; e.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'cdn.siftscience.com/s.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(e, s); } if (window.attachEvent) { window.attachEvent('onload', ls); } else { window.addEventListener('load', ls, false); } })();
  </script>
</body>
</html>
`
