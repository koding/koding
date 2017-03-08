module.exports = (options = {}) ->

  options.logo or= '/a/images/favicon.ico'

  """
  <!-- favicon -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Koding" />
  <link rel="apple-touch-icon" sizes="180x180" href="/a/favicon/apple-touch-icon.png?v=wAvxkwgmmY">
  <link rel="icon" type="image/png" href="/a/favicon/favicon-32x32.png?v=wAvxkwgmmY" sizes="32x32">
  <link rel="icon" type="image/png" href="/a/favicon/favicon-16x16.png?v=wAvxkwgmmY" sizes="16x16">
  <link rel="manifest" href="/a/favicon/manifest.json?v=wAvxkwgmmY">
  <link rel="mask-icon" href="/a/favicon/safari-pinned-tab.svg?v=wAvxkwgmmY" color="#5271a7">
  <link rel="shortcut icon" href="#{options.logo}?v=wAvxkwgmmY">
  <meta name="application-name" content="Koding">
  <meta name="msapplication-TileColor" content="#5271a7">
  <meta name="msapplication-TileImage" content="/a/favicon/mstile-144x144.png?v=wAvxkwgmmY">
  <meta name="msapplication-config" content="/a/favicon/browserconfig.xml?v=wAvxkwgmmY">
  <meta name="theme-color" content="#d9e0ec">
  """
