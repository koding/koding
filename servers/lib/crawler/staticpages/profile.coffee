{ getProfile }             = require '../helpers'
{ getAvatarImageUrl }      = require './activity'
{ getSidebar }             = require './feed'

module.exports = (account, statusUpdates, index, currentUrl) ->
  getGraphMeta = require './graphmeta'
  analytics    = require './analytics'

  { profile:{ nickname } } = account  if account

  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>#{nickname} - Koding</title>
    <style>body, html {height: 100%}</style>
    #{getGraphMeta({ index })}
  </head>
  <body itemscope itemtype="http://schema.org/WebPage" class="super profile">
    <div id="kdmaincontainer" class="kdview with-sidebar">
      #{getSidebar currentUrl}
      #{putContent(account, statusUpdates)}
    </div>
    #{analytics()}
  </body>
  </html>
  """

putContent = (account, statusUpdates) ->
  profile      = getProfile account

  unless statusUpdates
    statusUpdates = """<div class="no-item-found">#{profile.fullName} has not shared any posts yet.</div>"""

  imgURL  = getAvatarImageUrl profile.hash, profile.avatar, 143
  content = """
  <section id="main-panel-wrapper">
    <div class='kdview kdtabpaneview content-display clearfix content-display-wrapper content-page active'>
      <div class="kdview member content-display">
        <aside class="kdview app-sidebar clearfix">
          <main itemscope itemtype="http://schema.org/Person">
            <a class="avatarview" href="/#{profile.nickname}" style="background-image: none; background-size: 143px 143px;">
              <img class="" width="143" height="143" src="#{imgURL}" style="opacity: 1;">
            </a>
            <h3 class="full-name">
              <span class="kdview kdcontenteditableview firstName" itemprop="givenName">#{profile.firstName}</span>
              <span class="kdview kdcontenteditableview lastName" itemprop="familyName">#{profile.lastName}</span>
            </h3>
          </main>
        </aside>
        <nav class="member-tabs"><a class="active" href="#">Posts</a></nav>
        <div class="app-content">
          <div class="kdview kdtabpaneview statuses clearfix active">
            <div class="kdview kdlistview kdlistview-default activity-related" itemscope itemtype="http://schema.org/UserComments">
              #{statusUpdates}
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
  """
