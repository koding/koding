# This file contains static HTML output which is generated with browser.
# Since Koding homepage is now serving static content, we're serving very same
# content to GoogleBot.

module.exports = ->

  getGraphMeta  = require './graphmeta'
  analytics  = require './analytics'

  """
  <!DOCTYPE html>
  <html lang="en" itemscope itemtype="http://schema.org/LocalBusiness">
    <head>
      <title>Koding | A New Way For Developers To Work</title>
      #{getGraphMeta()}
      <style rel="stylesheet">
        #koding-logo {
          font-size: 18px;
          color : transparent;
          width: 120px;
          height: 30px;
          display: inline-block;
          background-position: -235px -719px;
          background-image: url("../images/_kd.sprites.png");
          background-repeat: no-repeat;
        }
      </style>
    </head>
    <body itemscope itemtype="http://schema.org/WebPage">
      <a id="koding-logo" href="http://koding.com">Coding environment from the future<span></span></a>
      <hr>
      <article>
        <header>Koding</header>
        <h1>
          Coding environment from the future.
        </h1>
        <p>
          Social development in your browser, sign up to join a great community and code on powerful VMs. Koding is an online IDE for Java, Javascript, CoffeeScript, Go, NodeJS and more!
        </p>
      </article>
      <hr>
      <article>
        <header><h3><a href="https://koding.com/Apps">Appstore</a></h3></header>
        <p>
          Speed up with user contributed apps, or create your own app, Koding has a great toolset to interact with VMs and to build UIs around.
        </p>
      </article>
      <hr>
      <article>
        <header><h3><a href="https://koding.com/Teamwork">Teamwork</a></h3></header>
        <p>
          Collaborative development environment for lecture groups, pair programming, or simply for sharing what you're doing with a total stranger.
        </p>
      </article>
      <hr>
      <article>
        <header><h3><a href="https://koding.com/Activity">Social</a></h3></header>
        <p>
          Share with the community, learn from the experts or help those who have yet to start coding. Socialize with like minded people and have fun.
        </p>
      </article>
      <hr>
      <article>
        <header><h2>Groups, have your own Koding</h2></header>
        <p>
          Have all your development needs in a single private space.
        </p>
      </article>
      <article>
        <header><h3>White-label Koding</h3></header>
        <p>
          You can have your private Koding in the cloud, with your rules, your apps and your own members. Please contact us for further information.
        </p>
      </article>
      <article>
        <header><h3>Use it in your school</h3></header>
        <p>
          Prepare your files online and share them with the whole class instantly. Collaborate live with your students or let them follow along what you're doing.
        </p>
      </article>
      <article>
        <header><h3>Create project groups</h3></header>
        <p>
          Want to work on a project with your buddies and use the same workspace? Share your VM with your fellow developers.
        </p>
      </article>
      <p>
        Get your own Koding for your team. Contact us for details.
      </p>
      <ul itemscope="itemscope" itemtype="http://schema.org/SiteNavigationElement" >
        <li>
          <a itemprop="url" href="mailto:hello@koding.com" >
            <div itemprop="name">Contact</div>
          </a>
        </li>
        <li>
          <a itemprop="url" href="http://learn.koding.com/">
            <div itemprop="name">University</div>
          </a>
        </li>
        <li>
          <a itemprop="url" href="http://koding.github.io/jobs/">
            <div itemprop="name">Jobs</div>
          </a>
        </li>
        <li>
          <a itemprop="url" href="http://blog.koding.com">
            <div itemprop="name">Blog</div>
          </a>
        </li>
      </ul>

      <div itemscope itemtype="http://schema.org/SoftwareApplication">
        <span itemprop="name">Koding</span> -

        <span itemprop="description">
          Social development in your browser, sign up to join a great community and code on powerful VMs. Koding is an online IDE for Java, Javascript, CoffeeScript, Go, NodeJS and more!
        </span>

        UPDATED: <time itemprop="datePublished" datetime="2009-06-30">2011</time>
        REQUIRES <span itemprop="operatingSystems">A modern browser, e.g. Google Chrome </span>: <span itemprop="operatingSystemVersion">20</span> and up
        <link itemprop="SoftwareApplicationCategory" href="http://schema.org/WebApplication"/>
        CATEGORY: <span itemprop="SoftwareApplicationSubCategory">Online IDE, Software Development Tools</span>
        INSTALLS: <meta itemprop="interactionCount" content=”UserDownloads:100000"/>100,000 - 500,000

        RATING:
        <div itemprop="aggregateRating" itemscope itemtype="http://schema.org/AggregateRating">
         <span itemprop="ratingValue">4.0</span>(
         <span itemprop="ratingCount">70872</span>)
         <meta itemprop="reviewCount" content="213" />
        </div>

        <div itemprop="offers" itemscope itemtype="http://schema.org/Offer">
         <span itemprop="price">Free</span>
        </div>

      </div>

      <div itemscope itemtype="http://schema.org/Organization">
        <span itemprop="name">Koding Inc.</span>
        <img src="https://koding.com/a/images/logos/fluid512.png" itemprop="image" width="100" height="100" />
        <div itemprop="address" itemscope itemtype="http://schema.org/PostalAddress">
          <span itemprop="streetAddress">
            Koding, Inc.
            358 Brannan Street
          </span>
          <span itemprop="addressLocality">San Francisco</span>,
          <span itemprop="addressRegion">CA</span>
          <span itemprop="postalCode">94107</span>
        </div>
        <a href="mailto:hello@koding.com" itemprop="email">
          hello@koding.com
        </a>
        #{analytics()}
    </body>
  </html>
  """
