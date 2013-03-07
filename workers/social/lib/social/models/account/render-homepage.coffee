
module.exports = ({profile,skillTags,counts})->
  content ?= getDefaultuserContents()
  {nickname, firstName, lastName, hash, about} = profile
  """
  <!DOCTYPE html>
  <html>
  <head>
    <title>#{nickname}</title>
    #{getStyles()}
  </head>
  <body class="login" data-profile="#{nickname}">
    <div id="profile-landing" class='profile-landing'>
    <div id="profile-landing-content" class="profile-landing-content">
      <div class="profile-wrapper">

        <span class="avatar">
          <img src="//gravatar.com/avatar/#{hash}?size=150&d=/images/defaultavatar/default.avatar.150.png}">
        </span>


        <div class="content-title">
          <a class="betatag">beta</a>
          #{firstName} #{lastName} <span class='nickname'>#{nickname}</span>
        </div>

        <div class="content-body">
          #{about}
        </div>

        <div class="content-meta">
          <div class="followers"><span class="icon"></span>
            <span class="count">#{counts?.followers or '0'}</span>
            <span class="text"> Followers</span>
          </div>

          <div class="following"><span class="icon"></span>
            <span class="count">#{counts?.following or '0'}</span>
            <span class="text"> Following</span>
          </div>

          <div class="likes"><span class="icon"></span>
            <span class="count">#{counts?.likes or '0'}</span>
            <span class="text"> Likes</span>
          </div>
          <div class="topics"><span class="icon"></span>
            <span class="count">#{counts?.topics or '0'}</span>
            <span class="text"> Topics</span>
          </div>
        </div>

      </div>
    </div>
    #{getScripts()}
    </div>
  </body>
  </html>
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
