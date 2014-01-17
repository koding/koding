# account and models will be removed.
{argv} = require 'optimist'
{uri, client} = require('koding-config-manager').load("main.#{argv.c}")

getSingleActivityPage = ({activityContent, account, models})->
  {Relationship} = require 'jraphical'
  getStyles      = require './styleblock'
  getGraphMeta   = require './graphmeta'
  model      = models.first if models and Array.isArray models

  title  = activityContent?.title
  """

  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>#{title} - Koding</title>
    #{getGraphMeta()}
  </head>
    <body itemscope itemtype="http://schema.org/WebPage">
      <a href="#{uri.address}">Koding</a><br />
      <article itemscope itemtype="http://schema.org/BlogPosting">
        #{getSingleActivityContent(activityContent, model)}
      </article>
    </body>
  </html>
  """


createCommentNode = (comment)->
  commentContent = ""
  if comment.body
    commentContent =
    """
    <li itemtype="http://schema.org/Comment" itemscope itemprop="comment">
        <span itemprop="commentText">#{comment.body}</span> - at
        <span itemprop="commentTime">#{comment.createdAt}</span> by
        <a href="#{uri.address}/#!/#{comment.authorNickname}"><span itemprop="name">#{comment.authorName}</span></a>
    </li>
    """
  return commentContent

createAccountName = (fullName)->
  return "#{fullName}"

createAvatarImage = (hash)->
  imgURL = "https://gravatar.com/avatar/#{hash}?size=90&amp;d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.90.png"
  """
  <img width="70" height="70" src="#{imgURL}" style="opacity: 1;" itemprop="image" />
  """

createCreationDate = (createdAt, url="")->
  """
    <a href='#{url}' class=><time>Created at: <span itemprop=\"dateCreated\">#{createdAt}</span></time></a>
  """

createCommentsCount = (numberOfComments)->
  content = ""
  if numberOfComments > 0
    content =  "<span>#{numberOfComments}</span> comments"
  return content

createLikesCount = (numberOfLikes)->
  content = ""
  if numberOfLikes > 0
    content = "<span>#{numberOfLikes}</span> likes."
  return content

createAuthor = (accountName, nickname)->
  return "<a href=\"#{uri.address}/#{nickname}\"><span itemprop=\"name\">#{accountName}</span></a>"

createUserInteractionMeta = (numberOfLikes, numberOfComments)->
  userInteractionMeta = "<meta itemprop=\"interactionCount\" content=\"UserLikes:#{numberOfLikes}\"/>"
  userInteractionMeta += "<meta itemprop=\"interactionCount\" content=\"UserComments:#{numberOfComments}\"/>"
  return userInteractionMeta

getSingleActivityContent = (activityContent, model)->

  slugWithDomain = "#{uri.address}/Activity/#{activityContent.slug}"

  body          = activityContent.body
  nickname      = activityContent.nickname
  accountName   = createAccountName activityContent.fullName
  avatarImage   = createAvatarImage activityContent.hash
  createdAt     = createCreationDate activityContent.createdAt, slugWithDomain
  commentsCount = createCommentsCount activityContent.numberOfComments
  likesCount    = createLikesCount activityContent.numberOfLikes
  author        = createAuthor accountName, nickname

  userInteractionMeta = createUserInteractionMeta \
    activityContent.numberOfLikes, activityContent.numberOfComments

  if activityContent?.comments?.length? > 0
    comments         = (createCommentNode(comment) for comment in activityContent.comments)
    commentsContent  = "<h4>Comments:</h4>"
    commentsContent += "<ol>"
    commentsContent += comments.join("")
    commentsContent += "</ol>"
  else
    commentsContent = ""

  tags = ""
  if activityContent?.tags?.length > 0
    tags = "tags: "
    for tag in activityContent.tags
      content =
        """
          <a href="#{uri.address}/#!/Topics/#{tag.slug}">#{tag.title}</a>
        """
      tags += content

  shortenedTitle = activityContent.title
  if shortenedTitle?.length > 150
    shortenedTitle = activityContent.title.substring(0, 150) + "..."
  title =
    """
      <a href="#{slugWithDomain}">#{shortenedTitle}</a>
    """

  content  =
    """
      <div class="kdview kdlistitemview kdlistitemview-activity">
          <div class="kdview activity-item status">
              <a class="avatarview author-avatar" href="#{uri.address}/#{nickname}" style="width: 70px; height: 70px; background-size: 70px; background-image: none;">
                  #{avatarImage}
              </a>

              <a class="profile" href="#{uri.address}/#{nickname}">
                <span data-paths="profile.firstName profile.lastName" itemscope itemtype="http://schema.org/person" title="#{accountName}">
                  #{accountName}
                </span>
              </a>

              <article data-paths="body">
                <p>
                  #{body}
                </p>
              </article>

              <footer>
                  #{userInteractionMeta}
                  <div class="kdview comment-header activity-actions">
                      <span class="kdview logged-in action-container"><a class="action-link" href="/Login">Like</a>
                          <a class="count" href="/Login">
                              <span data-paths="meta.likes">#{likesCount}</span>
                          </a>
                      </span>
                      <span class="logged-in action-container">
                          <a class="action-link" href="/Login">Comment</a>
                          <a class="count" href="/Login">
                              <span data-paths="repliesCount" >#{commentsCount}</span>
                          </a>
                      </span>
                  </div>
                  #{createdAt}
              </footer>
          </div>
      </div>
      #{commentsContent}
    """
  return content

module.exports = {
  getSingleActivityPage
  getSingleActivityContent
}
