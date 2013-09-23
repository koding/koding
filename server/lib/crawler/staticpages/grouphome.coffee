module.exports = ({group})->
  {body, title} = group

  getStyles       = require './styleblock'
  getSidebar      = require './sidebar'
  encoder         = require 'htmlencode'

  """

  <!DOCTYPE html>
  <html>
  <head>
    <title>#{encoder.XSSEncode title}</title>
    #{getStyles()}
  </head>
  <body class="group">

  <div class="kdview" id="kdmaincontainer">
    <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
    <header class="kdview" id='main-header'>
      <div class="kdview">
        <a class="group" id="koding-logo" href="#"><span></span>#{encoder.XSSEncode title}</a>
      </div>
    </header>
    <section class="kdview" id="main-panel-wrapper">
      #{getSidebar()}
      <div class="kdview full" id="content-panel">
        <div class="kdview kdscrollview kdtabview" id="main-tab-view">
          <div id='maintabpane-activity' class="kdview content-area-pane activity content-area-new-tab-pane clearfix kdtabpaneview active">
            <div id="content-page-activity" class="kdview content-page activity kdscrollview">
              <div class="kdview screenshots" id="home-group-header" >
                <section id="home-group-body" class="kdview kdscrollview">
                  <div class="group-desc">#{encoder.XSSEncode body}</div>
                </section>
                <div class="home-links" id="group-home-links">
                  <div class='overlay'></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
  </body>
  </html>

  """
