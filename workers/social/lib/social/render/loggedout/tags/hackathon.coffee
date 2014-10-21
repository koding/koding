title       = 'Koding | World\'s First Virtual Global Hackathon'
shareUrl    = 'https://koding.com/WFGH'
description = 'The World’s First Virtual Global Hackathon. This event is intended to connect developers across the globe and get them to  code together irrespective of their locations. You will problem solve and build with old or new team members and try to win!'

module.exports =

  """
  <title>#{title}</title>
  <meta name="description"             content="#{description}" />

  <!-- og meta tags -->
  <meta property="og:title" content="#{title}"/>
  <meta property="og:type" content="website"/>
  <meta property="og:url" content="#{shareUrl}"/>
  <meta property="og:image" content="http://koding.com/a/images/logos/share_logo.png"/>
  <meta property="og:image:secure_url" content="https://koding.com/a/images/logos/share_logo.png"/>
  <meta property="og:description" content="#{description}"/>
  <meta property="og:image:type" content="png">
  <meta property="og:image:width" content="400"/>
  <meta property="og:image:height" content="300"/>

  <!-- twitter cards -->
  <meta name="twitter:site" content="@koding"/>
  <meta name="twitter:url" content="#{shareUrl}"/>
  <meta name="twitter:title" content="#{title}"/>
  <meta name="twitter:creator" content="@koding"/>
  <meta name="twitter:card" content="summary"/>
  <meta name="twitter:image" content="https://koding.com/a/images/logos/share_logo.png"/>
  <meta name="twitter:description" content="#{description}"/>
  <meta name="twitter:domain" content="koding.com">
  """