# This file contains static HTML output which is generated with browser.
# Since Koding homepage is now serving static content, we're serving very same
# content to GoogleBot.

module.exports = ->

  getGraphMeta  = require './graphmeta'

  """

  <!DOCTYPE html>
  <html lang="en"><head>
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
  <body itemscope itemtype="http://schema.org/WebPage">
    <a id="koding-logo" href="http://koding.com">KODING<span></span></a>
    <h1>Software development has finally evolved,<br> It's now social, in the browser and free!</h1>
    <hr>
    <article>
      <header><h2>Koding for you</h2></header>
      <p>
        You have great ideas.  You want to meet brilliant minds, and bring those ideas to life.  You want to start simple.  Maybe soon you'll have a 10 person team, commanding 100s of servers.
      </p>
      <p>
        You want to learn Python, Java, C, Go, Nodejs, HTML, CSS or Javascript or any other. Community will help you along the way.
      </p>
    </article>
    <hr>
    <article>
      <header><h2>Koding for Developers</h2></header>
      <p>
        You will have an amazing virtual machine that is better than your laptop.  It's connected to the internet 100s of times faster.  You can share it with anyone you wish. Clone git repos.  Test and iterate on your code without breaking your setup.
      </p>
      <p>
        It's free. Koding is your new localhost, in the cloud.
      </p>
    </article>
    <hr>
    <article>
      <header><h2>Koding for Education</h2></header>
      <p>
        Create a group where your students enjoy the resources you provide to them. Make it private or invite-only.  Let them share, collaborate and submit their assignments together.  It doesn't matter if you have ten students, or ten thousand.  Scale from just one to hundreds of computers.
      </p>
      <p>
        Koding is your new classroom.
      </p>
    </article>
    <hr>
    <article>
      <header><h2>Koding for Business</h2></header>
      <p>
        When you hire someone, they can get up to speed in your development environment in 5 minutes—easily collaborating with others and contributing code.  All without sharing ssh keys or passwords.  Stop cc'ing your team; stop searching through old emails.
      </p>
      <p>
        Koding is your new workspace.
      </p>
    </article>
    <hr>
    <article>
      <header><h2>Pricing</h2></header>
      <p>
        You'll be able to buy more resources for your personal account or for accounts in your organization.
      </p>
    </article>
  """
