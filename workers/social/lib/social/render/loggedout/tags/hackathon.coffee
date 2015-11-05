origin      = 'koding.com'
title       = 'World\'s First Virtual Global Hackathon | Koding'
shareUrl    = "https://#{origin}/Hackathon2014"
description = 'This event is intended to connect developers across the globe and get them to  code together irrespective of their locations. You will problem solve and build with old or new team members and try to win!'
gpImage     = "#{origin}/a/site.hackathon/images/share.hackathon.g+.jpg?#{KONFIG.version}"
fbImage     = "#{origin}/a/site.hackathon/images/share.hackathon.fb.jpg?#{KONFIG.version}"
twImage     = "#{origin}/a/site.hackathon/images/share.hackathon.tw.jpg?#{KONFIG.version}"

module.exports =

  """
  <title>#{title}</title>
  <meta name="description"             content="#{description}" />

  <!-- Schema.org for Google+ -->
  <meta itemprop="name"                content="#{title}">
  <meta itemprop="description"         content="#{description}">
  <meta itemprop="url"                 content="#{shareUrl}">
  <meta itemprop="image"               content="http://#{gpImage}">

  <!-- og meta tags -->
  <meta property="og:title"            content="#{title}"/>
  <meta property="og:type"             content="website"/>
  <meta property="og:url"              content="#{shareUrl}"/>
  <meta property="og:image"            content="http://#{fbImage}"/>
  <meta property="og:image:secure_url" content="https://#{fbImage}"/>
  <meta property="og:description"      content="#{description}"/>
  <meta property="og:image:type"       content="image/jpeg">
  <meta property="og:image:width"      content="1200"/>
  <meta property="og:image:height"     content="627"/>

  <!-- twitter cards -->
  <meta name="twitter:site"            content="@koding"/>
  <meta name="twitter:url"             content="#{shareUrl}"/>
  <meta name="twitter:title"           content="#{title}"/>
  <meta name="twitter:creator"         content="@koding"/>
  <meta name="twitter:author"          content="@koding"/>
  <meta name="twitter:card"            content="summary_large_image"/>
  <meta name="twitter:image"           content="http://#{twImage}"/>
  <meta name="twitter:description"     content="#{description}"/>
  <meta name="twitter:domain"          content="koding.com">
  """


