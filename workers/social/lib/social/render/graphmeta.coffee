encoder      = require 'htmlencode'

#module.exports = (title = "A new way for developers to work.", shareUrl = "https://koding.com")->
module.exports = (options = {})->
  options.title ?= "A new way for developers to work."
  options.shareUrl ?= "https://koding.com"
  options.image ?= "https://koding.com/a/images/koding_share.jpg"
  options.body ?= "Koding is a developer community and cloud development environment where developers come together and code in the browser – with a real development server to run their code. Developers can work, collaborate, write and run apps without jumping through hoops and spending unnecessary money."

  """
  <meta name="title" content="Koding - A new way for developers to work.">
  <meta name="description" content="Koding is a developer community and cloud development environment where developers come together and code in the browser.">
  <meta name="keywords" content="online IDE, collaborative IDE, online code editor, web based php editor, browser-based terminal, free virtual machine, online java IDE, coffeescript, nodejs, golang">
  <meta name="author" content="Koding">
  <meta name="fragment" content="!">
  <meta property="og:site_name" content="Koding"/>
  <meta property="og:description" content="#{encoder.XSSEncode options.body}"/>
  <meta property="og:title" content="Koding - #{encoder.XSSEncode options.title}"/>
  <meta property="og:url" content="#{options.shareUrl}"/>
  <meta property="og:image" content="#{options.image}"/>
  <meta property="og:image:secure_url" content="#{options.image}"/>
  <meta property="og:image:type" content="image/jpeg">
  """
