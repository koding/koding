{ getProfile }             = require '../helpers'
{ getAvatarImageUrl }      = require './activity'
{ getSidebar }             = require './feed'

module.exports = (account, statusUpdates)=>
  getGraphMeta = require './graphmeta'
  analytics    = require './analytics'

  {profile:{nickname}} = account  if account

  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>#{nickname} - Koding</title>
    #{getGraphMeta()}
  </head>
    <body class='koding profile' itemscope itemtype="http://schema.org/WebPage">
      #{putContent(account, statusUpdates)}
      #{analytics()}
    </body>
  </html>
  """

putContent = (account, statusUpdates)=>
  profile      = getProfile account

  if statusUpdates is ""
    statusUpdates = """<div class="lazy-loader">#{profile.fullName} has not shared any posts yet.</div>"""

  numberOfLikes     = if account?.counts?.likes     then account.counts.likes     else "0"
  numberOfFollowers = if account?.counts?.followers then account.counts.followers else "0"
  numberOfFollowing = if account?.counts?.following then account.counts.following else "0"

  imgURL = getAvatarImageUrl profile.hash, profile.avatar, 143
  content  =
    """
    <div id="kdmaincontainer" class="kdview with-sidebar">
      #{getSidebar()}
      <section id="main-panel-wrapper" class="kdview">
        <div id="main-tab-view" class="kdview kdscrollview kdtabview">
          <div class="kdview kdtabpaneview content-display clearfix content-display-wrapper content-page active">
            <div class="kdview member content-display" style="min-height: 1274px;">
              <aside class="kdview app-sidebar clearfix">
                <main>
                  <span class="avatarview" href="/#{profile.nickname}" style="background-image: none; background-size: 143px 143px;">
                    <img class="" width="143" height="143" src="#{imgURL}" style="opacity: 1;">
                  </span>
                  <h3 class="full-name">
                    <span class="kdview kdcontenteditableview firstName">#{profile.firstName}</span>
                    <span class="kdview kdcontenteditableview lastName">#{profile.lastName}</span>
                  </h3>
                  <div>
                  </div>
                  <div class="profilestats">
                    <a class="kdview" href=""><span>#{numberOfFollowers}</span>Followers</a>
                    <a class="kdview" href=""><span>#{numberOfFollowing}</span>Following</a>
                    <a class="kdview" href=""><span>#{numberOfLikes}</span>Likes</a>
                  </div>
                </main>
              </aside>
              <nav class="member-tabs"><a class="active" href="#">Posts</a></nav>
              <div class="app-content">
                <div class="kdview kdtabpaneview statuses clearfix active">
                  <section>
                    #{statusUpdates}
                  </section>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
