# account and models will be removed.
module.exports = ({activityContent, account, section, models})->
  {Relationship} = require 'jraphical'
  getStyles  = require './styleblock'
  getGraphMeta  = require './graphmeta'
  model      = models.first if models and Array.isArray models

  """
  <!doctype html>
  <html lang="en">
  <head>
    <title>Koding</title>
    #{getStyles()}
    #{getGraphMeta()}
  </head>
    <body class='koding' itemscope itemtype="http://schema.org/WebPage">
      <div id='main-loading' class="kdview main-loading" itemscope itemtype="http://schema.org/BlogPosting">
        #{putContent(activityContent, section, model)}
      </div>
      <div class="kdview home" id="kdmaincontainer">
      </div>
    </body>
  </html>
  """
createCommentNode = (comment)->
  commentContent = ""
  if comment.body
    commentContent =
    """
    <li><span itemtype=\"http://schema.org/Comment\" itemscope itemprop=\"comment\"><span itemprop=\"commentText\">#{comment.body}</span> at <span itemprop=\"commentTime\">#{comment.createdAt}</span> \
      by <span itemprop=\"name\">#{comment.authorName}</span></span></li>
    """
  return commentContent

createAccountName = (fullName)->
  return " by <span itemprop='author'>#{fullName}</span>"

createAvatarImage = (hash)->
  imgURL = "https://gravatar.com/avatar/#{hash}?size=90&amp;d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.90.png"
  image = 
    """
    <img class=\"avatarview\" style=\"width: 90px; height: 90px;\" src=\"#{imgURL}\" itemprop=\"image\"/>
    """
  return image

createCreationDate = (createdAt)->
  return "Created at: <span itemprop=\"dateCreated\">#{createdAt}</span>"

createCommentsCount = (numberOfComments)->
  return "<span>#{numberOfComments}</span> comments"

createLikesCount = (numberOfLikes)->
  return "<span>#{numberOfLikes}</span> likes."

createCodeSnippet = (code)->
  codeSnippet = ""
  if code
    codeSnippet = "<pre>#{code}</pre>"
  return codeSnippet

createUserInteractionMeta = (numberOfLikes, numberOfComments)->
  userInteractionMeta = "<meta itemprop=\"interactionCount\" content=\"UserLikes:#{numberOfLikes}\"/>"
  userInteractionMeta += "<meta itemprop=\"interactionCount\" content=\"UserComments:#{numberOfComments}\"/>"
  return userInteractionMeta

putContent = (activityContent, section, model)->

  body = activityContent.body

  accountName = createAccountName activityContent.fullName
  avatarImage = createAvatarImage activityContent.hash
  createdAt = createCreationDate activityContent.createdAt
  commentsCount = createCommentsCount activityContent.numberOfComments
  likesCount = createLikesCount activityContent.numberOfLikes

  userInteractionMeta = createUserInteractionMeta \
    activityContent.numberOfLikes, activityContent.numberOfComments

  codeSnippet = createCodeSnippet activityContent.codeSnippet

  if activityContent.numberOfComments > 0
    comments = (createCommentNode(comment) for comment in activityContent.comments)
    commentsContent = "<h4>Comments:</h4>"
    commentsContent += "<ol style='text-align:left; list-style: none'>"
    commentsContent += comments.join("")
    commentsContent += "</ol>"
  else 
    commentsContent = ""

  tags = ""
  if activityContent?.tags?.length > 0
    tags = """<span>tags: #{activityContent.tags.join(',')}</span>"""

  title  = activityContent?.title

  content  =
    """<figure class='splash' style="color:white">
         <h2>
           #{title}
         </h2>
         <h3>
           #{avatarImage} [ #{body} #{codeSnippet}] #{accountName}
         </h3>
         #{userInteractionMeta}
         #{createdAt}<br />
         #{tags}<br />
         #{commentsCount}, 
         #{likesCount}<br />
         #{commentsContent}
       </figure>
    """
