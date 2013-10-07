module.exports = ({account, name, section, models})->

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
    <body class='koding'>
      <div id='main-loading' class="kdview main-loading" itemscope itemtype="http://schema.org/BlogPosting">
        #{putContent(name, section, model, account)}
      </div>
      <div class="kdview home" id="kdmaincontainer">
      </div>
    </body>
  </html>
  """

putContent = (name, section, model, account)->
  name = if model?.title then model.title else section
  body = if model?.body  then model.body  else ""

  accountName = ""
  if account?.data?.profile?.nickname
    accountName = 
      """ by <span itemprop="author">#{account.data.profile.nickname}</span>"""

  avatarImg = ""
  if account?.data?.profile?.hash
    imgURL = "https://gravatar.com/avatar/#{account.data.profile.hash}?size=90&amp;d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.90.png"
    avatarImg = 
      """
        <span class="avatarview" style="width: 90px; height: 90px; background-image: url(#{imgURL});"></span>
      """

  createdAt = ""
  if model?.data?.meta?.createdAt
    createdAt = 
      """Created at: <span itemprop="dateCreated">#{model.data.meta.createdAt}</span>"""

  tags = ""
  if model?.data?.meta?.tags
    tags = """<span>tags: #{model.data.meta.tags}</span>"""

  title  = if model?.bongo_?.constructorName
    # console.log model.bongo_.constructorName
    switch model.bongo_.constructorName
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
         #{createdAt}
         #{tags}
       </figure>
    """
