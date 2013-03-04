
module.exports = ({slug, title, content, body, avatar, counts, policy})->
  content ?= getDefaultGroupContents()
  """
  <!DOCTYPE html>
  <html>
  <head>
    <title>#{title}</title>
    #{getStyles()}
  </head>
  <body class="login" data-group="#{slug}">
    <div id="group-landing" class='group-landing'>
    <div id="group-landing-content" class="group-landing-content">
      <div class="group-wrapper">

        <span class="avatar">
          <img src="#{avatar or "http://lorempixel.com/150/150/"}">
        </span>

        <div class="content-title">
          <a class="betatag">beta</a>
          #{title}
        </div>

        <div class="content-body">
          #{body}
        </div>

        <div class="content-meta">
          <div class="members"><span class="icon"></span>
            <span class="count">#{counts?.members or '0'}</span>
            <span class="text"> Members</span>
          </div>
        </div>

        <div id="group-content-wrapper" class="group-content">
          <div class="content-markdown has-markdown dark">
            #{content}
          </div>
        </div>

      </div>
    </div>

    <div class="group-navigation">
      #{getNavigation policy}
    </div>
    </div>
    #{KONFIG.getConfigScriptTag groupEntryPoint: slug}
    #{getScripts()}
  </body>
  </html>
  """

getInviteLink =(policy)->
  if policy.approvalEnabled
    '<p class="bigLink"><a href="./Join">Request an Invite</a></p>'
  else ''

getNavigation =(policy)->
  """
  <div class="group-login-buttons"></div>
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


getDefaultGroupContents =->
  """
  Hi —

  This is a group on Koding.  It doesn't have a readme.  That's all we know.

  Sincerly,
  The Internet
  """.replace /\n/g, '<br>'
