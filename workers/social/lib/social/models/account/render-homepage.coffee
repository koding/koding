
module.exports = ({profile,skillTags,counts,lastBlogPosts,content})->
  content ?= getDefaultuserContents()
  {nickname, firstName, lastName, hash, about, handles} = profile

  firstName ?= 'Koding'
  lastName  ?= 'User'
  nickname  ?= ''
  about     ?= ''

  """
  <!DOCTYPE html>
  <html>
  <head>
    <title>#{nickname}</title>
    #{getStyles()}
  </head>
  <body class="login" data-profile="#{nickname}">
    <div class="profile-landing" id='static-landing-page' data-profile="#{nickname}">

    <div class="profile-personal-wrapper kdview collapsed" id="profile-personal-wrapper">
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
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator">
            <hr class="">
          </div>
        </div>
       </div>


      <div class="profile-koding-logo">
        <div class="logo kdview" id='profile-koding-logo'></div>
      </div>

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
    postDate = require('dateformat')(blog.meta.createdAt,'mmmm dS, yyyy "at" hh:MM:ss TT')
    posts+="""
      <div class="content-item static">
        <div class="title"><span class="text">#{blog.title}</span><span class="create-date">written on #{postDate}</span></div>
        <div class="has-markdown">
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
