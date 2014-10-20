title       = 'Koding | Say goodbye to your localhost and write code in the cloud'
shareUrl    = 'https://koding.com'
description = 'Koding is a cloud-based development environment complete with free VMs, IDE & sudo enabled terminal where you can learn Ruby, Go,  Java, NodeJS, PHP, C, C++, Perl, Python, etc.'

module.exports =

  """
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