module.exports = ->

  getHomeIntro = require './homeintro'
  getStyles    = require './styleblock'
  getScripts   = require './scriptblock'
  getSidebar   = require './sidebar'
  getCounters  = require './counters'

  """

  <!doctype html>
  <html lang="en">
  <head>
    <title>Koding</title>
    #{getStyles()}
  </head>
  <body class='koding'>

    <!--[if IE]>
    <script>(function(){window.location.href='/unsupported.html'})();</script>
    <![endif]-->

    <div class="kdview" id="kdmaincontainer">
      <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
      <header class="kdview" id='main-header'>
        <a id="koding-logo" href="#"><span></span></a>
      </header>
      #{getHomeIntro()}
      <section class="kdview" id="main-panel-wrapper">
        #{getSidebar()}
        <div class="kdview" id="content-panel">
          <div class="kdview kdscrollview kdtabview" id="main-tab-view">
            <div id='maintabpane-home' class="kdview content-area-pane activity content-area-new-tab-pane clearfix kdtabpaneview active">
              <div id="content-page-home" class="kdview content-page home kdscrollview">
                <div class="kdview screenshots extra-wide" id="home-header">
                  <div class="home-links kdview" id="home-login-bar">
                    <a class="custom-link-view browse orange" href="/Join"><span class="icon"></span><span class="title">Learn more...</span></a>
                    <a class="custom-link-view join green" href="/Join"><span class="icon"></span><span class="title">Request an Invite</span></a>
                    <a class="custom-link-view register" href="/Register"><span class="icon"></span><span class="title">Register an account</span></a>
                    <a class="custom-link-view login" href="/Login"><span class="icon"></span><span class="title">Login</span></a>
                  </div>
                  #{getCounters()}
                </div>
                <div class="kdview activity-content feeder-tabs">
                  <div class="kdview listview-wrapper">
                    <div class="kdview feeder-header clearfix"><span>Featured Activity</span></div>
                    <div class="kdview kdscrollview">
                      <div class="kdview kdlistview kdlistview-default activity-related"></div>
                      <div class="lazy-loader">Loading...</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>

  #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
  #{getScripts()}
  </body>
  </html>
  """