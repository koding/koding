package templates

var LoggedOutHome = `
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
  <link rel="stylesheet" href="/a/site.landing/css/kd.css?{{.Version}}" />
  <link rel="stylesheet" href="/a/site.landing/css/main.css?{{.Version}}" />
</head>
<body class='home'>

  <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

  <script src="/a/site.landing/js/libs.js?{{.Version}}"></script>
  <script src="/a/site.landing/js/kd.libs.js?{{.Version}}"></script>
  <script src="/a/site.landing/js/kd.js?{{.Version}}"></script>
  <script src="/a/site.landing/js/main.js?{{.Version}}"></script>

  {{template "analytics"}}
</body>
</html>
`
