module.exports = (options = {}) ->

  """
  <meta charset="utf-8"/>
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
  <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />

  #{require('./favicon')(options)}

  <link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
  <link href="https://plus.google.com/+KodingInc" rel="publisher" />
  <link rel="stylesheet" type="text/css" href="/a/p/p/#{KONFIG._CLIENTVERSION}/bundle.vendor.css" />
  <link rel="stylesheet" type="text/css" href="/a/p/p/#{KONFIG._CLIENTVERSION}/bundle.main.css" />
  """
