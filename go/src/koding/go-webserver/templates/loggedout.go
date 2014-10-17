package templates

var LoggedOutHome = `
<!doctype html>
<html lang="en">
<head>
  {{template "header" . }}

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
