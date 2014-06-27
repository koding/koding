{argv}  = require 'optimist'
encoder = require 'htmlencode'
{uri}   = require('koding-config-manager').load("main.#{argv.c}")
{ formatDate, getProfile, getAvatarImageUrl } = require '../helpers'

createLinkToStatusUpdate = (createDate, slug) ->
  content =
    """
    <a href="#{uri.address}/Activity/#{slug}"><time class="kdview">#{createDate}</time></a>
    """
  return content

createStatusUpdateNode = (statusUpdate, profile)=>
  {meta:{createdAt}} = statusUpdate  if statusUpdate
  createdAt          = if createdAt then formatDate createdAt else ""
  slug               = if statusUpdate?.slug then statusUpdate.slug else ""

  linkToStatusUpdate = createLinkToStatusUpdate createdAt, slug

  commentsList = ""
  if statusUpdate?.replies
    for comment in statusUpdate.replies
      profile = getProfile comment.author
      avatarUrl = getAvatarImageUrl profile.hash, profile.avatar
      nickname = encoder.XSSEncode profile.nickname
      fullname = encoder.XSSEncode profile.fullName

      commentsList +=
        """
          <div class="kdview kdlistitemview kdlistitemview-comment">
            <a class="avatarview online" href="/#{comment.author.nickname}" style="width: 40px; height: 40px; background-size: 40px; background-image: none;"><img class="" width="40" height="40" src="#{avatarUrl}" style="opacity: 1;"></a>
            <div class="comment-contents clearfix">
              <a class="profile" href="/#{nickname}" itemprop="name">#{fullname}</a>
              <div class="comment-body-container"><p itemprop="commentText">#{comment.body}</p></div>

            </div>
          </div>
        """

  commentsContent =
    """
      <div class="kdview comment-container commented">
        <div class="kdview listview-wrapper">
          <div class="kdview kdscrollview">
            <div class="kdview kdlistview kdlistview-comments">
              #{commentsList}
            </div>
          </div>
        </div>
      </div>
    """

  marked = require 'marked'

  body = marked statusUpdate.body,
    gfm       : true
    pedantic  : false
    sanitize  : true

  statusUpdateContent = ""
  if statusUpdate?.body
    statusUpdateContent =
    """
    <div class="kdview activity-item status">
      <a class="profile" href="/#{profile.nickname}">#{profile.fullName}</a>
      <article data-paths="body" id="el-1223">
        <p>#{body}</p>
      </article>
      <footer>#{linkToStatusUpdate}</footer>
      #{commentsContent}
    </div>
    """
  return statusUpdateContent

createLinkToUserProfile = (fullName, nickname) ->
  content =
    """
      <a href=\"#{uri.address}/#{nickname}\">#{fullName}</a>
    """
  return content

getStatusUpdates = (statusUpdates, profile) ->
  linkToProfile = createLinkToUserProfile profile.fullName, profile.nickname
  if statusUpdates?.length > 0
    updates = (createStatusUpdateNode(statusUpdate, profile) for statusUpdate in statusUpdates)
    updatesContent = updates.join("")
  else
    updatesContent =
    """
    <div class="lazy-loader">#{profile.fullName} has not shared any posts yet.</div>
    """
  return updatesContent


module.exports = (account, statusUpdates)=>
  getStyles    = require './styleblock'
  getGraphMeta = require './graphmeta'
  analytics    = require './analytics'

  {profile:{nickname}} = account  if account

  profile = getProfile account
  sUpdates = getStatusUpdates statusUpdates, profile, (err, sUpdates) ->
  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>#{nickname} - Koding</title>
    #{getGraphMeta()}
  </head>
    <body class='koding profile' itemscope itemtype="http://schema.org/WebPage">
      #{putContent(account, sUpdates)}
      #{analytics()}
    </body>
  </html>
  """

putContent = (account, sUpdates)=>
  getGraphMeta = require './graphmeta'
  profile      = getProfile account

  numberOfLikes     = if account?.counts?.likes     then account.counts.likes     else "0"
  numberOfFollowers = if account?.counts?.followers then account.counts.followers else "0"
  numberOfFollowing = if account?.counts?.following then account.counts.following else "0"

  imgURL = getAvatarImageUrl profile.hash, profile.avatar
  content  =
    """
    <div id="kdmaincontainer" class="kdview">
      #{getDock()}
      <section id="main-panel-wrapper" class="kdview">
        <div id="main-tab-view" class="kdview kdscrollview kdtabview">
          <div class="kdview kdtabpaneview content-display clearfix content-display-wrapper content-page active">
            <div class="kdview member content-display" style="min-height: 735px;">
              <div class="kdview profilearea clearfix">
                <div class="users-profile clearfix" itemscope itemtype="http://schema.org/Person">
                  <span class="avatarview" href="/#{profile.nickname}" style="width: 81px; height: 81px; background-size: 81px; background-image: none;">
                    <img class="" width="81" height="81" src="#{imgURL}" style="opacity: 1;" itemprop="image">
                  </span>
                  <h3 class="full-name">
                    <span class="kdview kdcontenteditableview firstName" itemprop="givenName">#{profile.firstName}</span>
                    <span class="kdview kdcontenteditableview lastName" itemprop="familyName">#{profile.lastName}</span>
                  </h3>
                  <div class="kdview kdcontenteditableview bio">
                    #{profile.about}
                  </div>
                  <div class="profilestats">
                    <a class="kdview" href="/#">
                      <span>#{numberOfFollowers}</span>Followers
                    </a>
                    <a class="kdview" href="/#">
                      <span>#{numberOfFollowing}</span>Following
                    </a>
                    <a class="kdview" href="/#">
                      <meta itemprop="interactionCount" content="UserLikes:#{numberOfLikes}"/>
                      <span>#{numberOfLikes}</span>Likes
                    </a>
                  </div>
                </div>
              </div>
              <div class="extra-wide">
                <div class="kdview kdtabview feeder-tabs">
                  <div class="kdview kdtabpaneview statuses clearfix active">
                    <div class="kdview kdlistview kdlistview-statuses activity-related">
                      <div class="kdview kdlistitemview kdlistitemview-activity" itemscope itemtype="http://schema.org/UserComments">
                        #{sUpdates}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
    """

