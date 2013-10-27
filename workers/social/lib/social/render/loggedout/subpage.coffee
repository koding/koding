module.exports = ({account, name, section, models})->

  getStyles  = require './../styleblock'
  getScripts = require './../scriptblock'
  model      = models.first if models and Array.isArray models
  isLoggedIn = account.type is "registered"

  """
  <!doctype html>
  <html lang="en">
  <head>
    <title>Koding</title>
    #{getStyles()}
  </head>
  <body class='koding'>

    <!--[if IE]>
    <script>(function(){window.location.href='/unsupported.html'})();</script>
    <![endif]-->

    <div id='main-loading' class="kdview main-loading">
        <figure class="threed-logo">
          <span class="line"><i></i></span>
          <span class="line"><i></i></span>
          <span class="line"><i></i></span>
          <span class="line"><i></i></span>
          <span class="line"><i></i></span>
          <span class="line"><i></i></span>
        </figure>
      #{putSplash(name, section, model)}
    </div>
    <div class="kdview" id="kdmaincontainer">
    </div>

    #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
    #{getScripts()}

  </body>
  </html>
  """

putSplash = (name, section, model)->
  name = if model?.title then model.title else section
  body = if model?.body  then model.body  else ""

  title  = if model?.bongo_?.constructorName
    # console.log model.bongo_.constructorName
    switch model.bongo_.constructorName
      when "JStatusUpdate"  then "loading a status update"
      when "JCodeSnip"      then "loading a code snippet"
      when "JDiscussion"    then "loading a discussion"
      when "JBlogPost"      then "loading a blog post"
      when "JTutorial"      then "loading a tutorial"
      when "JTag"           then "loading a topic"
      when "JApp"           then "loading a koding app page"
      else "loading something."
  else "launching an application"

  content  = "<figure class='splash'><h2 class='splash-title'>Please wait, #{title}:</h2>"
  content += "<h3 class='splash-name'>#{name.substr 0, 100}#{if name.length > 100 then '...' else ''}</h3></figure>"
