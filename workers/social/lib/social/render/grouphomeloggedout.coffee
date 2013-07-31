module.exports = ({account, slug, title, content, body, avatar, counts, policy, customize})->

  content ?= getDefaultGroupContents(title)

  getStyles       = require './styleblock'
  getScripts      = require './scriptblock'
  getSidebar      = require './sidebar'

  """

  <!DOCTYPE html>
  <html>
  <head>
    <title>#{title}</title>
    #{getStyles()}
  </head>
  <body class="group">

  <div class="kdview" id="kdmaincontainer">
    <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
    <header class="kdview" id='main-header'>
      <div class="kdview">
        <a class="group" id="koding-logo" href="#"><span></span>#{title}</a>
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
                  <div class="group-desc">#{body or getDefaultGroupContents()}</div>
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

getDefaultGroupContents = (title)->
  """
  <h1>Hello!</h1>
  <p>Welcome to the <strong>#{title}</strong> group on Koding.<p>
  <h2>Talk.</h2>
  <p>Looking for people who share your interest? You are in the right place. And you can discuss your ideas, questions and problems with them easily.</p>
  <h2>Share.</h2>
  <p>Here you will be able to find and share interesting content. Experts share their wisdom through links or tutorials, professionals answer the questions of those who want to learn.</p>
  <h2>Collaborate.</h2>
  <p>You will be able to share your code, thoughts and designs with like-minded enthusiasts, discussing and improving it with a community dedicated to improving each other's work.</p>
  <p>Go ahead, the members of <strong>#{title}</strong> are waiting for you.</p>
  """
