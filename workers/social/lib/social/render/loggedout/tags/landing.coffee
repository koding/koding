title       = 'Koding | Say goodbye to your localhost and write code in the cloud'
shareUrl    = 'https://koding.com'
description = 'Koding is a cloud-based development environment complete with free VMs, IDE & sudo enabled terminal where you can learn Ruby, Go,  Java, NodeJS, PHP, C, C++, Perl, Python, etc.'
image       = 'koding.com/a/images/logos/share_logo.png'

module.exports =

  """
  <title>#{title}</title>
  <meta name="description"             content="#{description}" />

  <!-- Schema.org for Google+ -->
  <meta itemprop="name"                content="#{title}">
  <meta itemprop="description"         content="#{description}">
  <meta itemprop="url"                 content="#{shareUrl}">
  <meta itemprop="image"               content="http://#{image}">

  <!-- og meta tags -->
  <meta property="og:title"            content="#{title}"/>
  <meta property="og:type"             content="website"/>
  <meta property="og:url"              content="#{shareUrl}"/>
  <meta property="og:image"            content="http://#{image}"/>
  <meta property="og:image:secure_url" content="https://#{image}"/>
  <meta property="og:description"      content="#{description}"/>
  <meta property="og:image:type"       content="png">
  <meta property="og:image:width"      content="400"/>
  <meta property="og:image:height"     content="400"/>

  <!-- twitter cards -->
  <meta name="twitter:site"            content="@koding"/>
  <meta name="twitter:url"             content="#{shareUrl}"/>
  <meta name="twitter:title"           content="#{title}"/>
  <meta name="twitter:creator"         content="@koding"/>
  <meta name="twitter:author"          content="@koding"/>
  <meta name="twitter:card"            content="summary"/>
  <meta name="twitter:image"           content="https://#{image}"/>
  <meta name="twitter:description"     content="#{description}"/>
  <meta name="twitter:domain"          content="koding.com">
  """