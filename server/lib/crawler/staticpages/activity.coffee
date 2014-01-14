# account and models will be removed.
{argv} = require 'optimist'
{uri} = require('koding-config-manager').load("main.#{argv.c}")

getSingleActivityPage = ({activityContent, account, models})->
  {Relationship} = require 'jraphical'
  getStyles  = require './styleblock'
  getGraphMeta  = require './graphmeta'
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
  image =
    """
    <img src="#{imgURL}" itemprop="image"/>
    """
  return image

createCreationDate = (createdAt)->
  return "Created at: <span itemprop=\"dateCreated\">#{createdAt}</span>"

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
  return "<a href=\"#{uri.address}/#!/#{nickname}\"><span itemprop=\"name\">#{accountName}</span></a>"

createUserInteractionMeta = (numberOfLikes, numberOfComments)->
  userInteractionMeta = "<meta itemprop=\"interactionCount\" content=\"UserLikes:#{numberOfLikes}\"/>"
  userInteractionMeta += "<meta itemprop=\"interactionCount\" content=\"UserComments:#{numberOfComments}\"/>"
  return userInteractionMeta

getSingleActivityContent = (activityContent, model)->
  body = activityContent.body
  nickname = activityContent.nickname
  accountName = createAccountName activityContent.fullName
  avatarImage = createAvatarImage activityContent.hash
  createdAt = createCreationDate activityContent.createdAt
  commentsCount = createCommentsCount activityContent.numberOfComments
  likesCount = createLikesCount activityContent.numberOfLikes
  author = createAuthor accountName, nickname

  userInteractionMeta = createUserInteractionMeta \
    activityContent.numberOfLikes, activityContent.numberOfComments

  if activityContent?.comments?.length? > 0
    comments = (createCommentNode(comment) for comment in activityContent.comments)
    commentsContent = "<h4>Comments:</h4>"
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
      <a href="#{uri.address}/#!/Activity/#{activityContent.slug}">#{shortenedTitle}</a>
    """

  content  =
    """
      <header itemprop="headline"><h1>#{title}</h1></header>
      #{body}
      <hr>
      <figure itemscope itemtype="http://schema.org/person" title="#{accountName}">
        #{avatarImage}
      </figure>
      <footer>
        #{userInteractionMeta}
        #{createdAt} by #{author}
        <br>
        #{tags}
        <hr>
        #{commentsCount} #{likesCount}
      </footer>
      #{commentsContent}
    """
  return content

module.exports = {
  getSingleActivityPage
  getSingleActivityContent
}
