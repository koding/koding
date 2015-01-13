package templates

var Header = `
    <title>{{.Title}}</title>

    <meta charset="utf-8"/>

    <meta name="description"             content="{{.Description}}" />
    <meta name="author"                  content="Koding">
    <meta name="keywords"                content="Web IDE, Cloud VM, VM, VPS, Ruby, Node, PHP, Python, Wordpress, Django, Programming, virtual machines">

    <!-- Schema.org for Google+ -->
    <meta itemprop="name"                content="{{.Title}}">
    <meta itemprop="description"         content="{{.Description}}">
    <meta itemprop="url"                 content="{{.ShareUrl}}">
    <meta itemprop="image"               content="http://{{.GpImage}}">

    <!-- og meta tags -->
    <meta property="og:title"            content="{{.Title}}"/>
    <meta property="og:type"             content="website"/>
    <meta property="og:url"              content="{{.ShareUrl}}"/>
    <meta property="og:image"            content="http://{{.FbImage}}"/>
    <meta property="og:image:secure_url" content="https://{{.FbImage}}"/>
    <meta property="og:description"      content="{{.Description}}"/>
    <meta property="og:image:type"       content="image/jpeg">
    <meta property="og:image:width"      content="1200"/>
    <meta property="og:image:height"     content="627"/>

    <!-- twitter cards -->
    <meta name="twitter:site"            content="@koding"/>
    <meta name="twitter:url"             content="{{.ShareUrl}}"/>
    <meta name="twitter:title"           content="{{.Title}}"/>
    <meta name="twitter:creator"         content="@koding"/>
    <meta name="twitter:author"          content="@koding"/>
    <meta name="twitter:card"            content="summary_large_image"/>
    <meta name="twitter:image"           content="http://{{.TwImage}}"/>
    <meta name="twitter:description"     content="{{.Description}}"/>
    <meta name="twitter:domain"          content="koding.com">

    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <meta name="apple-mobile-web-app-title" content="Koding" />
    <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />

    <link rel="shortcut icon" href="/a/images/favicon.ico" />
    <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
    <link href='https://chrome.google.com/webstore/detail/koding/fgbjpbdfegnodokpoejnbhnblcojccal' rel='chrome-webstore-item'>

    <script>
    var _prum = [['id', '54a5cf1eabe53d1d20d455ec'],
                 ['mark', 'firstbyte', (new Date()).getTime()]];
    (function() {
        var s = document.getElementsByTagName('script')[0]
          , p = document.createElement('script');
        p.async = 'async';
        p.src = '//rum-static.pingdom.net/prum.min.js';
        s.parentNode.insertBefore(p, s);
    })();
    </script>
`
