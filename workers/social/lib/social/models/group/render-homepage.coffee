module.exports = ({slug, title, content, body, avatar, counts, policy, roles, description})->
  content ?= getDefaultGroupContents(title)
  """

  <!DOCTYPE html>
  <html>
  <head>
    <title>#{title}</title>
    #{getStyles()}
  </head>
  <body class="login">

    #{getLoader roles}

    <div id="static-landing-page">

    <div class="group-personal-wrapper" id="group-personal-wrapper">
      <div class="group-avatar" style="background-image:url(http://lorempixel.com/160/160/)">

      </div>
      <div class="group-buttons">
        <div class="group-nickname">#{slug}</div>
      </div>
      <div id="main-loader"></div>
      <div id="landing-page-sidebar"></div>

      <div class="profile-koding-logo">
        <div class="logo" id='profile-koding-logo'></div>
      </div>

    </div>

    <div class="group-content-wrapper" id="group-content-wrapper">
      <div class="group-title" id="group-title">
        <div class="group-title-wrapper" id="group-title-wrapper">
          <div class="group-name">#{title}</div>
          <div class="group-bio">#{body}</div>
        </div>
      </div>
      <div class="group-splitview" id="group-splitview">
        <div class="group-content-links">
          <h4>Show me</h4>
          <ul>
            <li class="" id="CBlogPostActivity">Blog Posts</li>
            <li class="" id="CStatusActivity">Status Updates</li>
            <li class="" id="CCodeSnipActivity">Code Snippets</li>
            <li class="" id="CDiscussionActivity">Discussions</li>
            <li class="" id="CTutorialActivity">Tutorials</li>
          </ul>
        </div>
        <div class="group-loading-content" id="group-loading-content">
         <div class="content-item" id='group-readme'>
           <div class="has-markdown">
             <span class="data">#{content}</span>
           </div>
         </div>
       </div>
      </div>
    </div>
    #{KONFIG.getConfigScriptTag {groupEntryPoint: slug, roles: roles}}
    #{getScripts()}
    </div>
  </body>
  </html>
  """

getLoader = (roles)->
  if 'member' in roles or 'admin' in roles
    return """
      <div id="main-koding-loader" class="kdview main-loading">
        <figure>
          <ul>
            <li></li>
            <li></li>
            <li></li>
            <li></li>
            <li></li>
            <li></li>
          </ul>
        </figure>
      </div>
    """
  return ''

getInviteLink =(policy)->
  if policy.approvalEnabled
    '<p class="bigLink"><a href="./Join">Request an Invite</a></p>'
  else ''

getNavigations = ->
  """
    <ul id='navigation-link-container' class='admin'></ul>
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


getDefaultGroupContents = (title)->
  """
  <h1>Hello!</h1>
  <p>Welcome to the #{title} group on Koding.<p>
  <h2>Talk.</h2>
  <p>Looking for people who share your interest? You are in the right place. And you can discuss your ideas, questions and problems with them easily.</p>
  <h2>Share.</h2>
  <p>Here you will be able to find and share interesting content. Experts share their wisdom through links or tutorials, professionals answer the questions of those who want to learn.</p>
  <h2>Collaborate.</h2>
  <p>You will be able to share your code, thoughts and designs with like-minded enthusiasts, discussing and improving it with a community dedicated to improving each other's work.</p>
  <p>Go ahead, the members of #{title} are waiting for you.</p>
  """#.replace /\n/g, '<br>'
