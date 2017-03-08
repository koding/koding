{ domains, version } = require 'koding-config-manager'

origin      = domains.base
title       = 'Modern Dev Environment Delivered · Koding'
shareUrl    = "https://#{origin}/"
description = 'Instantly create, share, scale, and manage development environments.'
keywords    = '''integrated development environment, cloud ide, dev environment,
                 cloud development environment, cloud editor, virtual dev environment,
                 web based ide, test environment, docker, aws, vagrant, azure, rackspace'''

gpImage     = "#{origin}/a/site.landing/images/share.g+.jpg?#{version}"
fbImage     = "#{origin}/a/site.landing/images/share.fb.jpg?#{version}"
twImage     = "#{origin}/a/site.landing/images/share.tw.jpg?#{version}"

module.exports =

  """
  <title>#{title}</title>
  <meta name="description"             content="#{description}" />
  <meta name="keywords"                content="#{keywords}">

  #{require('../favicon')()}

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
  <meta name="twitter:domain"          content="#{domains.base}">
  """
