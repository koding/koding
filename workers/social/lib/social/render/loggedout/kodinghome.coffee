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
              <div id="content-page-home" class="kdview content-page home kdscrollview extra-wide">

              </div>
            </div>
          </div>
        <div id="main-tab-handle-holder" class="kdview kdtabhandlecontainer"></div>
      </section>
    </div>

  #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
  #{getScripts(yes)}
  </body>
  </html>
  """