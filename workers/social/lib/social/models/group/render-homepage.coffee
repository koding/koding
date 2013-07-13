module.exports = ({slug, title, content, body, avatar, counts, policy, customize})->

  content ?= getDefaultGroupContents(title)

  """

  <!DOCTYPE html>
  <html>
  <head>
    <title>#{title}</title>
    #{getStyles()}
  </head>
  <body class="group">

  <div class="kdview" id="kdmaincontainer">
    <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
    <header class="kdview" id='main-header'>
      <a class="group" id="koding-logo" href="#"><span></span>#{title}</a>
    </header>
    <section class="kdview" id="main-panel-wrapper">
      <div class="kdview" id="sidebar-panel">
        <div class="kdview" id="sidebar">
          <div id="main-nav">
            <div class="avatar-placeholder">
              <div id="avatar-area">
                <div class="avatarview avatar-image-wrapper" style="width: 160px; height: 76px; background-image: url(//api.koding.com/images/defaultavatar/default.avatar.160.png);"></div>
              </div>
            </div>
            <div class="kdview actions">
              <a class="notifications" href="#"><span class="count"><cite>0</cite></span><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
              <a class="messages" href="#"><span class="count"><cite>0</cite></span><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
              <a class="group-switcher" href="#"><span class="count"><cite>0</cite><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
            </div>
            <div class="kdview status-leds"></div>
            <div class="kdview kdlistview kdlistview-navigation">
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix selected">
                <a class="title" href="#"><span class="main-nav-icon home"></span>Home</a>
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                <a class="title" href="#"><span class="main-nav-icon activity"></span>Activity</a>
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                <a class="title"><span class="main-nav-icon topics"></span>Topics</a>
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                <a class="title"><span class="main-nav-icon members"></span>Members</a>
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                <a class="title"><span class="main-nav-icon groups"></span>Groups</a>
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                <a class="title"><span class="main-nav-icon develop"></span>Develop</a>
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
                <a class="title"><span class="main-nav-icon apps"></span>Apps</a>
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator">
                <hr class="">
              </div>
              <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account">
                <a class="title" href="#"><span class="main-nav-icon invite-friends"><span data-paths="quota usage">0</span></span>Invite Friends</a>
              </div>
            </div>
            <div class="kdview kdlistview kdlistview-footer-menu">
              <div class="kdview kdlistitemview kdlistitemview-default help"><span></span></div>
              <div class="kdview kdlistitemview kdlistitemview-default about"><span></span></div>
              <div class="kdview kdlistitemview kdlistitemview-default chat"><span></span></div>
            </div>
          </div>
          <div id="finder-panel"></div>
        </div>
      </div>
      <div class="kdview" id="content-panel">
        <div class="kdview kdscrollview kdtabview" id="main-tab-view">
          <div id='maintabpane-activity' class="kdview content-area-pane activity content-area-new-tab-pane clearfix kdtabpaneview active">
            <div id="content-page-activity" class="kdview content-page activity kdscrollview">
              <div class="kdview screenshots" id="home-group-header" >
                <section id="home-group-body" class="kdview kdscrollview">
                  <div class="group-desc">#{body}</div>
                </section>
                <div class="home-links" id="group-home-links">
                  <div class='overlay'></div>
                  <a class="custom-link-view browse orange" href="#"><span class="icon"></span><span class="title">Learn more...</span></a><a class="custom-link-view join green" href="/#{slug}/Join"><span class="icon"></span><span class="title">Request an Invite</span></a><a class="custom-link-view register" href="/#{slug}/Register"><span class="icon"></span><span class="title">Register an account</span></a><a class="custom-link-view login" href="/#{slug}/Login"><span class="icon"></span><span class="title">Login</span></a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>

  #{KONFIG.getConfigScriptTag {entryPoint: { slug : slug, type: "group"}, roles:['guest'], permissions:[]}}
  #{getScripts()}
  </body>
  </html>

  """

applyCustomBackground = (customize={})->

  defaultImages = [
                    '/images/bg/blurred/1.jpg','/images/bg/blurred/5.jpg'
                    '/images/bg/blurred/2.jpg','/images/bg/blurred/6.jpg',
                    '/images/bg/blurred/3.jpg','/images/bg/blurred/7.jpg',
                    '/images/bg/blurred/4.jpg','/images/bg/blurred/8.jpg',
                  ]

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

# getLoader = (roles)->

#   if 'member' in roles or 'admin' in roles
#     return """
#       <div id="main-koding-loader" class="kdview main-loading">
#         <figure>
#           <ul>
#             <li></li>
#             <li></li>
#             <li></li>
#             <li></li>
#             <li></li>
#             <li></li>
#           </ul>
#         </figure>
#       </div>
#     """
#   return ''

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
    require(["order!/js/highlightjs/highlight.pack.js","order!/js/kd.#{KONFIG.version}.js"]);
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
  <script type="text/javascript">(function(e,b){if(!b.__SV){var a,f,i,g;window.mixpanel=b;a=e.createElement("script");a.type="text/javascript";a.async=!0;a.src=("https:"===e.location.protocol?"https:":"http:")+'//cdn.mxpnl.com/libs/mixpanel-2.2.min.js';f=e.getElementsByTagName("script")[0];f.parentNode.insertBefore(a,f);b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!== typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");for(g=0;g<i.length;g++)f(c,i[g]); b._i.push([a,e,d])};b.__SV=1.2}})(document,window.mixpanel||[]); mixpanel.init("e25475c7a850a49a512acdf04aa111cf");</script>

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
