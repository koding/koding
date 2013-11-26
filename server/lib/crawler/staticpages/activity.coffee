# account and models will be removed.
{argv} = require 'optimist'
{uri} = require('koding-config-manager').load("main.#{argv.c}")

module.exports = ({activityContent, account, section, models})->
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
      <article itemscope itemtype="http://schema.org/BlogPosting">
        #{putContent(activityContent, section, model)}
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
  return "<span>#{numberOfComments}</span> comments"

createLikesCount = (numberOfLikes)->
  return "<span>#{numberOfLikes}</span> likes."

createAuthor = (accountName, nickname)->
  return "<a href=\"#{uri.address}/#!/#{nickname}\"><span itemprop=\"name\">#{accountName}</span></a>"

createCodeSnippet = (code)->
  codeSnippet = ""
  if code
    codeSnippet = "<code>#{code}</code>"
  return codeSnippet

createUserInteractionMeta = (numberOfLikes, numberOfComments)->
  userInteractionMeta = "<meta itemprop=\"interactionCount\" content=\"UserLikes:#{numberOfLikes}\"/>"
  userInteractionMeta += "<meta itemprop=\"interactionCount\" content=\"UserComments:#{numberOfComments}\"/>"
  return userInteractionMeta

putContent = (activityContent, section, model)->

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

  codeSnippet = createCodeSnippet activityContent.codeSnippet

  if activityContent.numberOfComments > 0
    comments = (createCommentNode(comment) for comment in activityContent.comments)
    commentsContent = "<h4>Comments:</h4>"
    commentsContent += "<ol>"
    commentsContent += comments.join("")
    commentsContent += "</ol>"
  else
    commentsContent = ""

  tags = ""
  if activityContent?.tags?.length > 0
    tags = """<span>tags: #{activityContent.tags.join(',')}</span><br>"""

  title  = activityContent?.title

  content  =
    """
        <a href="#{uri.address}">Koding</a><br />
        <header itemprop="headline"><h1>#{title}</h1></header>
        #{body} #{codeSnippet}
        <hr>
        <figure itemscope itemtype="http://schema.org/person" title="#{accountName}">
          #{avatarImage}
          <figcaption>
            Author: #{author}
          </figcaption>
        </figure>
        <footer>
          #{userInteractionMeta}
          #{createdAt} by #{author}
          <br>
          #{tags}
          <hr>
          #{commentsCount}, #{likesCount}
        </footer>
        #{commentsContent}
    """
