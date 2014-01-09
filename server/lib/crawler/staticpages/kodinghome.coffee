# This file contains static HTML output which is generated with browser.
# Since Koding homepage is now serving static content, we're serving very same
# content to GoogleBot.

module.exports = ->

  getGraphMeta  = require './graphmeta'

  """
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <title>Koding</title>
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
        Koding in the classroom, prepare your files online, share them with the whole class instantly. Collaborate live or just make your students watch what you're doing.
      </p>
    </article>
    <article>
      <header><h3>Create project groups</h3></header>
      <p>
        Want to work on a project with your buddies and use the same resources and running instances, share a VM between your fellow developers.
      </p>
    </article>
    <p>
      Get your own Koding for your team. Contact us for details.
    </p>
  """
