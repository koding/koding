package templates

var Header = `
    <title>{{.Title}}</title>
    <meta name="description" content="{{.Description}}">
    <meta name="author" content="Koding">
    <meta name="keywords" content="Web IDE, Cloud VM, VM, VPS, Ruby, Node, PHP, Python, Wordpress, Django, Programming, virtual machines">

    <meta charset="utf-8"/>

    <!-- og meta tags -->
    <meta property="og:title" content="{{.Title}}"/>
    <meta property="og:type" content="website"/>
    <meta property="og:url" content="{{.ShareUrl}}"/>
    <meta property="og:image" content="http://koding.com/a/images/logos/share_logo.png"/>
    <meta property="og:image:secure_url" content="https://koding.com/a/images/logos/share_logo.png"/>
    <meta property="og:description" content="{{.Description}}"/>
    <meta property="og:image:type" content="png">
    <meta property="og:image:width" content="400"/>
    <meta property="og:image:height" content="300"/>

    <!-- twitter cards -->
    <meta name="twitter:site" content="@koding"/>
    <meta name="twitter:url" content="{{.ShareUrl}}"/>
    <meta name="twitter:title" content="{{.Title}}"/>
    <meta name="twitter:creator" content="@koding"/>
    <meta name="twitter:card" content="summary"/>
    <meta name="twitter:image" content="https://koding.com/a/images/logos/share_logo.png"/>
    <meta name="twitter:description" content="{{.Description}}"/>
    <meta name="twitter:domain" content="koding.com">

    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <meta name="apple-mobile-web-app-title" content="Koding" />
    <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />

    <link rel="shortcut icon" href="/a/images/favicon.ico" />
    <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
    <link href='https://chrome.google.com/webstore/detail/koding/fgbjpbdfegnodokpoejnbhnblcojccal' rel='chrome-webstore-item'>
`
