module.exports = ({account, client}, callback)->

  getStyles       = require './../styleblock'
  fetchScripts    = require './../scriptblock'
  getInnerNav     = require './../innernav'
  getSidebar      = require './sidebar'
  getStatusWidget = require './statuswidget'


  prepareHTML = ({scripts})->
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
          <div class="kdview">
            <a id="koding-logo" href="#"><span></span></a>
          </div>
        </header>
        <section class="kdview" id="main-panel-wrapper">

          #{getSidebar account}

          <div class="kdview transition social" id="content-panel">
            <div class="kdview kdscrollview kdtabview" id="main-tab-view">
              <div id='maintabpane-activity' class="kdview content-area-pane activity content-area-new-tab-pane clearfix kdtabpaneview active">
                <div id="content-page-activity" class="kdview content-page activity kdscrollview fixed loggedin">
                  #{getStatusWidget account}
                  #{getInnerNav()}
                  <div class="kdview activity-content feeder-tabs">
                    <div class="kdview listview-wrapper">
                      <div class="kdview feeder-header clearfix"><span>Latest Activity</span></div>
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
      #{scripts}

    </body>
    </html>
    """

  fetchScripts {client, intro : no}, (err, scripts)->
    callback null, prepareHTML {scripts}


