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


    <script>(function(){window.location.href='/unsupported.html'})();</script>


    <div class="kdview home" id="kdmaincontainer">
      <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
      <header class="kdview" id='main-header'>
        <div class="kdview">
          <a id="koding-logo" href="#" class='large'><span></span></a>
          <a id="header-sign-in" class="custom-link-view login" href="#!/Login"><span class="title" data-paths="title">Already a user? Sign In.</span><span class="icon"></span></a>
        </div>
      </header>
      #{getHomeIntro()}
      <section class="kdview" id="main-panel-wrapper">
        #{getSidebar()}
        <div class="kdview" id="content-panel">
          <div class="kdview kdscrollview kdtabview" id="main-tab-view">
            <div id='maintabpane-home' class="kdview content-area-pane activity content-area-new-tab-pane clearfix kdtabpaneview active">
              <div id="content-page-home" class="kdview content-page home kdscrollview extra-wide">
                <div id='featured-activities-container' class="kdview activity-content feeder-tabs">
                  <div class="kdview listview-wrapper">
                    <div class="kdview feeder-header clearfix"><span>What's going on in the Koding Community</span></div>
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