# account and models will be removed.
module.exports = ({activityContent, account, name, section, models})->
  {Relationship} = require 'jraphical'
  getStyles  = require './styleblock'
  getGraphMeta  = require './graphmeta'
  model      = models.first if models and Array.isArray 

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
        #{putContent(activityContent, name, section, model)}
      </div>
      <div class="kdview home" id="kdmaincontainer">
      </div>
    </body>
  </html>
  """
createCommentNode = (comment)->
  if comment
    return "<li><span itemprop=\"commentText\">#{comment.body}</span> at <span itemprop=\"commentTime\">#{comment.createdAt}</span> \
      by <span itemprop=\"name\">#{comment.name}</span></li>"
  else return ""

putContent = (activityContent, name, section, model)->

  name = activityContent.name
  body = activityContent.body

  # Ugly spaghetti HTML exceeding 80 characters.
  accountName = " by <span itemprop='author'>#{activityContent.fullName}</span>"
  imgURL = "https://gravatar.com/avatar/#{activityContent.hash}?size=90&amp;d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.90.png"
  avatarImg = "<span class=\"avatarview\" style=\"width: 90px; height: 90px; background-image: url(#{imgURL});\"></span>"
  createdAt = "Created at: <span itemprop=\"dateCreated\">#{activityContent.createdAt}</span>"
  commentsCount = "<span>#{activityContent.numberOfComments}</span> comments"
  likesCount = "<span>#{activityContent.numberOfLikes}</span> likes."

  userInteractionMeta = "<meta itemprop=\"interactionCount\" content=\"UserLikes:#{activityContent.numberOfLikes}\"/>"
  userInteractionMeta += "<meta itemprop=\"interactionCount\" content=\"UserComments:#{activityContent.numberOfComments}\"/>"
  
  comments = (createCommentNode(comment) \
    for comment in activityContent.comments when comment.body)

  commentsContent = "<h4>Comments:</h4>"
  commentsContent += "<ol style='text-align:left' itemscope itemtype=\"http://schema.org/UserComments\">"
  commentsContent += comments.join("")
  commentsContent += "</ol>"

  tags = ""
  if activityContent?.tags
    tags = """<span>tags: #{activityContent.tags}</span>"""

  title  = if activityContent?.type
    # console.log model.bongo_.constructorName
    switch activityContent.type
      when "JStatusUpdate"  then "status update"
      when "JCodeSnip"      then "code snippet"
      when "JDiscussion"    then "discussion"
      when "JBlogPost"      then "blog post"
      when "JTutorial"      then "tutorial"
      when "JTag"           then "topic"
      when "JApp"           then "koding app page"
      else "loading something."
  else "launching an application"

  content  =
    """<figure class='splash' style="color:white">
         <h2>
           #{title}
         </h2>
         <h3>
           #{avatarImg} [ #{body} ] #{accountName}
         </h3>
         #{userInteractionMeta}
         #{createdAt}<br />
         #{tags}<br />
         #{commentsCount}, 
         #{likesCount}<br />
         #{commentsContent}
       </figure>
    """
