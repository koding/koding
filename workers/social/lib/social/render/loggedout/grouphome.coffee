module.exports = ({account, slug, title, content, body, avatar, counts, policy, customize})->

  getStyles       = require './../styleblock'
  getScripts      = require './../scriptblock'
  getGraphMeta    = require './../graphmeta'
  getSidebar      = require './sidebar'
  encoder         = require 'htmlencode'

  """

  <!DOCTYPE html>
  <html prefix="og: http://ogp.me/ns#">
  <head>
    <title>#{encoder.XSSEncode title}</title>
    #{getStyles()}
    #{getGraphMeta()}
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
                  <a class="custom-link-view browse orange" href="#"><span class="icon"></span><span class="title">Learn more...</span></a><a class="custom-link-view join green" href="/#{slug}/Login"><span class="icon"></span><span class="title">Request an Invite</span></a><a class="custom-link-view register" href="/#{slug}/Register"><span class="icon"></span><span class="title">Register an account</span></a><a class="custom-link-view login" href="/#{slug}/Login"><span class="icon"></span><span class="title">Login</span></a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>

  #{KONFIG.getConfigScriptTag {entryPoint: { slug : slug, type: "group"}, roles:['guest'], permissions:[]}}
  #{getScripts()}
  </body>
  </html>

  """
getInviteLink =(policy)->
  if policy.approvalEnabled
    '<p class="bigLink"><a href="./Login">Request an Invite</a></p>'
  else ''
