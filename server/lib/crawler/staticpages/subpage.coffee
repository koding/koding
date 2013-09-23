module.exports = ({account, name, section, models})->

  getStyles  = require './styleblock'
  model      = models.first if models and Array.isArray models

  """
  <!doctype html>
  <html lang="en">
  <head>
    <title>Koding</title>
    #{getStyles()}
  </head>
    <body class='koding'>
      <div id='main-loading' class="kdview main-loading">
        #{putSplash(name, section, model)}
      </div>
      <div class="kdview home" id="kdmaincontainer">
      </div>
    </body>
  </html>
  """

putSplash = (name, section, model)->
  name = if model?.title then model.title else section
  body = if model?.body  then model.body  else ""

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
    """<figure class='splash'>
          <h2 class='splash-title'>
            #{title}
          </h2>
          <h3 class='splash-name'>
            [ #{body} ]
          </h3>
       </figure>
    """
