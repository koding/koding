module.exports = ({slug, title, content, body, avatar, counts, policy, roles, description, customize})->
  content ?= getDefaultGroupContents(title)

  """

  <!DOCTYPE html>
  <html>
  <head>
    <title>#{title}</title>
    #{getStyles()}
  </head>
  <body class="login landing">

    #{getLoader roles}

    <div id="static-landing-page">

      <div class="group-content-wrapper" id="group-content-wrapper" #{applyCustomBackground customize}>
        <div class="group-splitview #{if customize?.background?.customType in ['defaultColor','customColor'] then 'vignette' else ''}" id="group-splitview">
          <div class="group-loading-content" id="group-loading-content">
           <div class="content-item kdview front" id='group-readme'>
             <div class="content-item-scroll-wrapper">
               <div class="group-title" id="group-title">
                 <div class="group-title-wrapper" id="group-title-wrapper">
                   <div class="group-name">#{title}</div>
                   <div class="group-bio">#{body}</div>
                 </div>
               </div>
               <div class="has-markdown">
                 <span class="data">#{content}</span>
               </div>
             </div>
           </div>
           <div class="content-item kdview back">
             <div class="content-item-scroll-wrapper" id='group-config'>
             </div>
           </div>

         </div>
        </div>
      </div>
    </div>
    #{KONFIG.getConfigScriptTag {groupEntryPoint: slug, roles: roles}}
    #{getScripts()}
  </body>
  </html>
  """

applyCustomBackground = (customize={})->

  defaultImages = ['/images/bg/bg01.jpg','/images/bg/bg02.jpg',
   '/images/bg/bg03.jpg','/images/bg/bg04.jpg','/images/bg/bg05.jpg',]

  if customize.background?.customType is 'defaultImage' \
  and customize.background?.customValue <= defaultImages.length
    url = defaultImages[(customize.background.customValue or 0)]
    """ style='background-color:transparent;background-image:url("#{url}")'"""
  else if customize.background?.customType is 'customImage'
    url = customize.background?.customValue
    """ style='background-color:transparent;background-image:url("#{url}")'"""
  else if customize.background?.customType in ['defaultColor','customColor']
    """ style='background-image:none;background-color:#{customize.background.customValue or "ffffff"}'"""
  else
    """ style='background-image:url("#{defaultImages[0]}")'"""




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
  <p>Welcome to the <strong>#{title}</strong> group on Koding.<p>
  <h2>Talk.</h2>
  <p>Looking for people who share your interest? You are in the right place. And you can discuss your ideas, questions and problems with them easily.</p>
  <h2>Share.</h2>
  <p>Here you will be able to find and share interesting content. Experts share their wisdom through links or tutorials, professionals answer the questions of those who want to learn.</p>
  <h2>Collaborate.</h2>
  <p>You will be able to share your code, thoughts and designs with like-minded enthusiasts, discussing and improving it with a community dedicated to improving each other's work.</p>
  <p>Go ahead, the members of <strong>#{title}</strong> are waiting for you.</p>
  """#.replace /\n/g, '<br>'
