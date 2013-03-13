
module.exports = ({profile,skillTags,counts,lastBlogPosts})->
  content ?= getDefaultuserContents()
  {nickname, firstName, lastName, hash, about} = profile

  firstName ?= 'Koding'
  lastName  ?= 'User'
  nickname  ?= ''
  about     ?= ''

  sortedTags = []
  skillTags ?= {}
  for i in [0...skillTags.length]
    sortedTags.push skillTags[i]
  sortedTags.sort()

  """
  <!DOCTYPE html>
  <html>
  <head>
    <title>#{nickname}</title>
    #{getStyles()}
  </head>
  <body class="login" data-profile="#{nickname}">
    <div id="profile-landing" class='profile-landing' data-profile="#{nickname}">

    <div class="profile-personal-wrapper" id="profile-personal-wrapper">
      <div class="profile-avatar" style="background-image:url(//gravatar.com/avatar/#{hash}?size=160&d=/images/defaultavatar/default.avatar.160.png)">

      </div>
      <div class="profile-buttons">
        <div class="profile-nickname">@#{nickname}</div>
      </div>
      <div class="profile-links">
        <ul class='main'>
          <li class='blog'><a href=""><span class="icon"></span>Blog</a></li>
          <li class='twitter'><a href=""><span class="icon"></span>Twitter</a></li>
          <li class='github'><a href=""><span class="icon"></span>GitHub</a></li>
        </ul>
        <hr/>

        #{getNavigations()}

      </div>
      <div class="profile-koding-logo">
        <div class="logo" id='profile-koding-logo'></div>
      </div>

    </div>

    <div class="profile-content-wrapper" id="profile-content-wrapper">
      <div class="profile-title" id="profile-title">
        <div class="profile-title-wrapper" id="profile-title-wrapper">
          <div class="profile-admin-message" id="profile-admin-message"></div>
          <div class="profile-name">#{firstName} #{lastName}</div>
          <div class="profile-bio">#{about}</div>
        </div>
      </div>
      <div class="profile-splitview" id="profile-splitview">
        <div class="profile-content-links">
          <h4>Show me</h4>
          <ul>
            <li>Everything</li>
            <li>Status Updates</li>
            <li>Code Snippets</li>
            <li>Discussions</li>
            <li>Tutorials</li>
            <li>Q&amp;A</li>
            <li>Links</li>
          </ul>
        </div>
        <div class="profile-content-list" id=class="profile-content-list">
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

getBlogPosts = (blogPosts=[],firstName,lastName)->
  posts = ""
  for blog,i in blogPosts
    postDate = require('dateformat')(blog.meta.createdAt,'dddd, mmmm dS, yyyy "at" h:MM:ss TT')
    posts+="""
      <div class="content-item">
        <div class="title"><span class="text">#{blog.title}</span><span class="create-date">#{postDate}</span></div>
        <div class="has-markdown">
          <span class="data">#{blog.html}</span>
        </div>
      </div>
    """
  if i>0
    posts
  else
    """
      <div class="content-item default-item">
        <div class="has-markdown"><span class="data">#{firstName} #{lastName} has not written any Blog Posts yet.</span></div>
      </div>
    """

getNavigations = ->
  """
    <ul id='navigation-link-container' class='admin'></ul>
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
      "order!/js/libs/jquery-ui-1.8.16.custom.min.js",
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
