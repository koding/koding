
module.exports = ({profile,skillTags,counts,lastBlogPosts,content})->
  content ?= getDefaultuserContents()
  {nickname, firstName, lastName, hash, about, handles, staticPage} = profile

  staticPage ?= {}
  {backgrounds} = staticPage

  firstName ?= 'Koding'
  lastName  ?= 'User'
  nickname  ?= ''
  about     ?= ''

  if backgrounds?.length
    console.log backgrounds.length, Math.floor(Math.random()*backgrounds.length)
    selectedBackground = backgrounds[Math.floor(Math.random()*backgrounds.length)]
    console.log selectedBackground

  """
  <!DOCTYPE html>
  <html>
  <head>
    <title>#{nickname}</title>
    #{getStyles()}
  </head>
  <body class="login" data-profile="#{nickname}">
    <div class="profile-landing #{if selectedBackground then 'custom-bg' else ''}" id='static-landing-page' data-profile="#{nickname}" #{if selectedBackground then "style='background-image:url(#{selectedBackground})'" else ''}>

    <div class="profile-personal-wrapper kdview" id="profile-personal-wrapper">
      <div class="profile-avatar" style="background-image:url(//gravatar.com/avatar/#{hash}?size=160&d=/images/defaultavatar/default.avatar.160.png)">

      </div>

      <div class="profile-buttons kdview actions" id="profile-buttons">

        <a class="static-profile-button notifications" href="#"><span class="count"><cite></cite><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
        <a class="static-profile-button messages" href="#"><span class="count"><cite></cite><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
        <a class="static-profile-button group-switcher" href="#"><span class="count"><cite></cite><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a></div>

      <!--<div class="profile-links">
        <ul class='main'>
          <li class='twitter'>#{getHandleLink 'twitter', handles}</li>
          <li class='github'>#{getHandleLink 'github', handles}</li>
        </ul>
      </div>-->

      <div id="landing-page-sidebar" class=" profile-sidebar kdview">
        <div class="kdview kdlistview kdlistview-navigation" id="profile-static-nav">
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix user invisible">
            <a class="title"><span class="main-nav-icon home"></span>Home</a>
          </div>
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix user">
            <a class="title"><span class="main-nav-icon activity"></span>Activity</a>
          </div>
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix user">
            <a class="title"><span class="main-nav-icon about"></span>About</a></div>
        </div>
       </div>

      <!--<div class="profile-placeholder" id="profile-placeholder"></div>

      <div class="profile-koding-logo" id="profile-koding-logo-wrapper">
        <div class="logo kdview" id='profile-koding-logo'></div>
        <a class="info kdview" id="profile-koding-logo-info">Go to Koding.com</a>
      </div>-->
      <div id="landing-page-avatar-drop" class="group-avatar-drop"></div>


    </div>

    <div class="profile-content-wrapper kdview" id="profile-content-wrapper">
      <div class="profile-title" id="profile-title">
        <div class="profile-title-wrapper" id="profile-title-wrapper">
          <div class="profile-admin-customize hidden" id="profile-admin-customize"></div>
          <div class="profile-admin-message" id="profile-admin-message"></div>
          <div class="profile-name" id="profile-name"><span class="text">#{getStaticProfileTitle profile}</span></div>
          <div class="profile-bio" id="profile-bio"><span class="text">#{getStaticProfileAbout profile}</span></div>
        </div>
      </div>
      <div class="profile-splitview" id="profile-splitview">
        <div class="profile-content-links links-hidden" id="profile-content-links">
          <h4>Show me</h4>
          <ul>
            <li class="" id="CBlogPostActivity">Blog Posts</li>
            <li class="disabled" id="CStatusActivity">Status Updates</li>
            <li class="disabled" id="CCodeSnipActivity">Code Snippets</li>
            <li class="disabled" id="CDiscussionActivity">Discussions</li>
            <li class="disabled" id="CTutorialActivity">Tutorials</li>
          </ul>
        </div>
        <div class="profile-loading-bar" id="profile-loading-bar"></div>
        <div class="profile-content-list" id="profile-content-list">
          <div class="profile-content" id="profile-content" data-count="#{lastBlogPosts.length or 0}">
            #{getBlogPosts(lastBlogPosts,firstName,lastName)}
            <div id="profile-show-more-wrapper" class="profile-show-more-wrapper hidden">
             <button id="profile-show-more-button" class="profile-show-more-button kdview clean-gray">Show more
             </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    #{KONFIG.getConfigScriptTag profileEntryPoint: profile.nickname}
    #{getScripts()}
    </div>
  </body>
  </html>
  """

getStaticProfileTitle = (profile)->
  {firstName,lastName,nickname,staticPage} = profile
  if staticPage?.title? and not (staticPage.title in [null, ''])
    "#{staticPage.title}"
  else
    if firstName and lastName then "#{firstName} #{lastName}"
    else if firstName then "#{firstName}"
    else if lastName then "#{lastName}"
    else "#{nickname}"

getStaticProfileAbout = (profile)->
  {about,staticPage} = profile
  if staticPage?.about? and not(staticPage.about in [null, ''])
    "#{staticPage.about}"
  else if about then "#{about}" else ""

getBlogPosts = (blogPosts=[],firstName,lastName)->
  posts = ""
  for blog,i in blogPosts

    slug = blog.slug
    href = ("/#{slug}" if 'string' is typeof slug) or "/#{slug.group}/#{slug.slug}" or '/#'

    if blog.tags?.length
      tags = ""
      for tag in blog.tags
        tags+="<a class='ttag' href='#'>#{tag.title}</a>"
      tagsList = " <div class='link-group'> in #{tags}</div>"
    else tagsList = ""

    postDate = require('dateformat')(blog.meta.createdAt,'mmmm dS, yyyy')

    commentCount =
      if blog.repliesCount is 0 then ''
      else if blog.repliesCount is 1 then ' One Comment'
      else " #{blog.repliesCount} Comments"

    likes = blog.meta?.likes or 0

    meta =
      if likes is 0 then ''
      else
        if likes is 1 then "One Like"
        else "#{likes} Likes"

    meta += "#{if commentCount isnt '' then " · " else ''}" if likes isnt 0


    posts+="""
      <div class="content-item static">
        <div class="title">
          <a href="#{href}" target='_blank'><span class="text">#{blog.title}</span></a>
        </div>
        <div class="has-markdown">
          <span class="create-date">
            <span>
              Published on #{postDate}#{tagsList}
            </span>
            <span>
              <span class="meta">#{meta}#{commentCount}</span>
            </span>
          </span>
          <span class="data">#{blog.html}</span>
        </div>
      </div>
    """
  if i>0
    posts
  else
    """
      <div class="content-item default-item" id='profile-blog-default-item'>
        <div class="has-markdown"><span class="data">#{firstName} #{lastName} has not written any Blog Posts yet.</span></div>
      </div>
    """

getHandleLink = (handle,handles)->

  handleMap =
    twitter :
      baseUrl : 'https://www.twitter.com/'
      text : 'Twitter'
      prefix : '@'

    github :
      baseUrl : 'https://www.github.com/'
      text : 'GitHub'

  if handles?[handle]
    """
      <a href='#{handleMap[handle].baseUrl}#{handles[handle]}' target='_blank' id='profile-handle-#{handle}'>
      <span class="icon"></span>
      #{handleMap[handle].prefix or ''}#{handles[handle]}
      </a>
    """
  else
    """
      <a href='#' id='profile-handle-#{handle}'>
      <span class="icon"></span>
      #{handleMap[handle].text}
      </a>
    """

getTags = (tags)->
  for value in tags
    """
    <div class='ttag' data-tag='#{value}'>#{value}</div>
    """

getStyles =->
  """
  <meta charset="utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
  <meta name="description" content="" />
  <meta name="author" content="" />
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Koding" />
  <meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />
  <link rel="shortcut icon" href="/images/favicon.ico" />
  <link rel="fluid-icon" href="/images/kd-fluid-icon512.png" title="Koding" />
  <link rel="stylesheet" href="/css/kd.#{KONFIG.version}.css" />
  <link rel="stylesheet" href="/fonts/stylesheet.css" />
  <link href="http://fonts.googleapis.com/css?family=Bree+Serif" rel="stylesheet" type="text/css">
  """

getScripts =->
  """
  <!--[if IE]>
  <script type="text/javascript">
    (function() { window.location.href = '/unsupported.html'})();
  </script>
  <![endif]-->

  <script src="/js/require.js"></script>

  <script>
    require.config({baseUrl: "/js", waitSeconds:15});
    require([
      "order!/js/libs/jquery-1.8.2.min.js",
      "order!/js/underscore-min.1.3.js",
      "order!/js/libs/highlight.pack.js",
      "order!/js/kd.#{KONFIG.version}.js",
    ]);
  </script>

  <script type="text/javascript">
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-6520910-8']);
    _gaq.push(['_setDomainName', 'koding.com']);
    _gaq.push(['_trackPageview']);
    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
  </script>
  """

getDefaultuserContents =->
  """
  Hi —

  This is a user on Koding.  It doesn't have a readme.  That's all we know.

  Sincerly,
  The Internet
  """.replace /\n/g, '<br>'
