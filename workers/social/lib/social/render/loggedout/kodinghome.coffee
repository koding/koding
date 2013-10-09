module.exports = ->

  getHomeIntro = require './../homeintro'
  getStyles    = require './../styleblock'
  getScripts   = require './../scriptblock'
  getGraphMeta = require './../graphmeta'
  getSidebar   = require './sidebar'

  """

  <!doctype html>
  <html lang="en" prefix="og: http://ogp.me/ns#">
  <head>
    <title>Koding</title>
    #{getStyles()}
    #{getGraphMeta()}
  </head>
  <body class='koding'>

    <!--[if IE]>
    <script>(function(){window.location.href='/unsupported.html'})();</script>
    <![endif]-->

    <div class="kdview home" id="kdmaincontainer">
      <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
      <header class="kdview" id='main-header'>
        <div class="kdview">
          <a id="koding-logo" href="#" class='large'><span></span></a>
          <a id="header-sign-in" class="custom-link-view login" href="#!/Login"><span class="title" data-paths="title">Login</span></a>
        </div>
      </header>
      #{getHomeIntro()}
      <section class="kdview" id="main-panel-wrapper">
        <div class="kdview" id="sidebar-panel">
          <div class="kdview" id="sidebar">
            <div id="main-nav">
              <div class="avatar-placeholder">
                <div id="avatar-area">
                  <div class="avatarview avatar-image-wrapper" title="View your public profile" >
                    <cite></cite>
                  </div>
                </div>
              </div>
              <div class="kdview actions">
                <a class="notifications" title="Notifications" href="#">
                  <span class="count">
                    <cite></cite>
                    <span class="arrow-wrap">
                      <span class="arrow"></span>
                    </span>
                  </span>
                  <span class="icon"></span>
                </a>
                <a class="messages" title="Messages" href="#">
                  <span class="count">
                    <cite></cite>
                    <span class="arrow-wrap">
                      <span class="arrow"></span>
                    </span>
                  </span>
                  <span class="icon"></span>
                </a>
                <a class="group-switcher" title="Your groups" href="#">
                  <span class="count">
                    <cite></cite>
                    <span class="arrow-wrap">
                      <span class="arrow"></span>
                    </span>
                  </span>
                  <span class="icon"></span>
                </a>
              </div>
              <div class="kdview kdlistview kdlistview-navigation">
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                  <a class="title" href="#">
                    <span class="main-nav-icon transparent hidden"></span>
                    <span class="main-nav-icon activity"></span>Activity
                  </a>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                  <a class="title">
                    <span class="main-nav-icon topics"></span>Topics
                  </a>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                  <a class="title">
                    <span class="main-nav-icon members"></span>Members
                  </a>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                  <a class="title">
                    <span class="main-nav-icon groups"></span>Groups
                  </a>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                  <a class="title">
                    <span class="main-nav-icon develop"></span>Develop
                  </a>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                  <a class="kdview title">
                    <span class="icon-top-badge hidden">0</span>
                    <span class="main-nav-icon apps"></span> Apps
                  </a>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator">
                  <hr class="">
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account docs">
                  <span class="title">
                    <span class="main-nav-icon docs-jobs"></span>
                    <a class="ext" href="http://koding.github.io/docs/" target="_blank">Docs</a> /
                    <a class="ext" href="http://koding.github.io/jobs/" target="_blank">Jobs</a>
                  </span>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator">
                  <hr class="">
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account">
                  <a class="title">
                    <span class="main-nav-icon login"></span>Login
                  </a>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account">
                  <a class="title">
                    <span class="main-nav-icon register"></span>Register
                  </a>
                </div>
              </div>
              <div class="kdview kdlistview kdlistview-footer-menu">
                <div class="kdview kdlistitemview kdlistitemview-default help">
                  <span class=""></span>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default about">
                  <span class=""></span>
                </div>
                <div class="kdview kdlistitemview kdlistitemview-default chat">
                  <span class=""></span>
                </div>
              </div>
            </div>
            <div id="finder-panel">
              <div id="finder-header-holder">
                <h2 class=""><span data-paths="profile.nickname">guest-60</span>.localhost</h2>
              </div>

              <div id="finder-dnduploader" class="kdview hidden">
                <div class="kdview file-droparea">
                  <div class="file-drop">
                    Drop files here!
                    <small>/home/guest-60/Uploads</small>
                  </div>
                </div>
              </div>

              <div id="finder-holder">
                <div class="kdview nfinder file-container">
                  <div class="kdview kdscrollview jtreeview-wrapper"></div>
                  <div class="kdview no-vm-found-widget">
                    <span class="kdview kdloader">
                      <span id="cl_kd-149" class="canvas-loader">
                        <canvas width="20" height="20"></canvas>
                        <canvas width="20" height="20"></canvas>
                      </span>
                    </span>
                    <div class="">There is no attached VM</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="kdview transition no-shadow full" id="content-panel">
          <div class="kdview kdscrollview kdtabview" id="main-tab-view">
            <div id="maintabpane-home" class="kdview content-area-pane activity content-area-new-tab-pane clearfix kdtabpaneview home active">
              <div id="content-page-home" class="kdview content-page home kdscrollview extra-wide"><section class="slider-section" id="slider-section">
                <div class="home-slider">
                  <div id="you-page" class="slider-page active">
                    <div class="wrapper">
                      <figure></figure>
                        <h3>
                          <i></i> Koding for <span>You</span>
                        </h3>
                        <p>
                          You have great ideas.  You want to meet brilliant minds, and bring those ideas to life.  You want to start simple.  Maybe soon you'll have a 10 person team, commanding 100s of servers.
                        </p>
                        <p>
                          You want to learn Python, Java, C, Go, Nodejs, HTML, CSS or Javascript or any other. Community will help you along the way.
                        </p>
                      </div>
                    </div>
                    <div id="developers-page" class="slider-page">
                      <div class="wrapper">
                        <figure></figure>
                        <h3>
                          <i></i> Koding for <span>Developers</span>
                        </h3>
                        <p>
                          You can have an amazing VM that is better than your laptop.  It's connected to internet 100x faster.  You can share it with anyone you wish. Clone git repos.  Test and iterate on your code without breaking your setup.
                        </p>
                        <p>
                          It's free. Koding is your new localhost, in the cloud.
                        </p>
                      </div>
                    </div>
                    <div id="education-page" class="slider-page">
                      <div class="wrapper">
                        <figure></figure>
                        <h3>
                          <i></i> Koding for <span>Education</span>
                        </h3>
                        <p>
                          Have a group where your students enjoy the resources you provide to them. Have it private, invite-only, let them share, collaborate and submit their assignments together.10 students, or 10,000. Just 1 or 100s of computers.
                        </p>
                        <p>
                          Koding is your new classroom.
                        </p>
                      </div>
                    </div>
                    <div id="business-page" class="slider-page">
                      <div class="wrapper">
                        <figure></figure>
                        <h3>
                          <i></i> Koding for <span>Business</span>
                        </h3>
                        <p>
                          When you hire someone, let them be in your environment in 5 minutes, collaborating with others, contributing code without sharing ssh keys, passwords. Stop cc'ing your team, stop looking for emails.
                        </p>
                        <p>
                          Koding is your new workspace.
                        </p>
                      </div>
                    </div>
                    <nav class="slider-nav">
                      <a class="custom-link-view active" href="#">
                        <span class="title" data-paths="title">You</span>
                      </a>
                      <a class="custom-link-view" href="#">
                        <span class="title" data-paths="title">Developers</span>
                      </a>
                      <a class="custom-link-view" href="#">
                        <span class="title" data-paths="title">Education</span>
                      </a>
                      <a class="custom-link-view" href="#">
                        <span class="title" data-paths="title">Business</span>
                      </a>
                    </nav>
                  </div>
                </section>
                <section class="pricing-section" id="pricing-section">
                  <h3>Simple Pricing</h3>
                  <h4>Try it and see if it's really as cool as we say</h4>
                  <div class="price-boxes">
                    <a href="#" class="free">
                      <span>Your first VM</span>
                      Free
                    </a>
                    <a href="#" class="paid">
                      <span>Each additional VM</span>
                      $5 / Month
                    </a>
                  </div>
                  <div class="pricing-details">
                    <span><strong>Always on*</strong> $25 / Month</span>
                    <span><strong>Extra RAM</strong> $10 / GB / Month</span><br>
                    <span><strong>Extra Disk Space</strong> $1 / GB / Month</span>
                    <span><strong>Firewall / Backend Builder</strong> $5 / Per VM / Month</span>
                  </div>
                  <span class="pricing-contact"><a href="mailto:hello@koding.com?Subject=Please%20tell%20me..." target="_top">Contact us</a> for Education and Business pricing</span>
                </section>
                <footer class="home-footer">
                  <section>
                    <div class="fl">
                      <span>© 2013 Koding, Inc.</span>
                      <a href="/tos.html" target="_blank">Terms</a>
                      <a href="/privacy.html" target="_blank">Privacy</a>
                    </div>
                    <div class="fr">
                      <a href="#">Status</a>
                      <a href="#">API</a>
                      <a href="http://blog.koding.com" target="_blank">Blog</a>
                      <a href="#">About</a>
                    </div>
                  </section>
                </footer>
              </div>
            </div>
          </div>
        <div id="main-tab-handle-holder" class="kdview kdtabhandlecontainer"></div>
      </section>
    </div>

  #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
  #{getScripts()}
  </body>
  </html>
  """