
module.exports = ({account,profile,skillTags,counts,isLoggedIn,content})->
  # content ?= getDefaultuserContents()
  {nickname, firstName, lastName, hash, about, handles, staticPage} = profile
  staticPage ?= {}
  {customize} = staticPage
  {locationTags,meta} = account
  firstName ?= 'Koding'
  lastName  ?= 'User'
  nickname  ?= ''
  about     ?= ''
  title = "#{firstName} #{lastName}"
  slug = nickname

  amountOfDays = Math.floor (new Date().getTime()-meta.createdAt)/(1000*60*60*24)

  """

  <!DOCTYPE html>
  <html>
  <head>
    <title>#{title}</title>
    #{getStyles()}
  </head>
  <body>

  <div class="kdview" id="kdmaincontainer">
    <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
    <header class="kdview" id='main-header'>
      <a id="koding-logo" href="#"><span></span></a>
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
      <div class="kdview #{if isLoggedIn then 'social' else 'full'}" id="content-panel">
        <div class="kdview kdscrollview kdtabview" id="main-tab-view">
        </div>

        <div id="content-display-wrapper" class="kdview content-display-wrapper in">
            <div id="member-contentdisplay" class="kdview member content-display">
                <h2 class="sub-header" id='members-sub-header'>
                    <a id='members-back-link' class="" href="#"><span>«</span> Back</a>
                </h2>
                <div id="profilearea" class="kdview profilearea clearfix">
                  <div class="profileleft">
                    <span>
                      <span class="avatarview" style="width: 90px; height: 90px; background-image: url(http://gravatar.com/avatar/#{profile.hash}?size=90&amp;d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.90.png);"></span>
                    </span>
                    <button type="button" class="kdbutton kdwhitebtn profilefollowbtn w-loader" id="kd-274"><span class="kdview kdloader hidden" style="width: 18px; height: 18px; position: absolute; left: 50%; top: 50%; margin-top: -9px; margin-left: -9px;"><span id="cl_kd-287" class="canvas-loader" style="display: none;"><canvas width="18" height="18"></canvas><canvas style="display: none;" width="18" height="18"></canvas></span></span>
                      <span class="icon hidden"></span>
                      <span class="button-title">Follow</span>
                    </button>
                    <cite class="data" data-paths="profile.nickname" id="el-98">@#{nickname}</cite>
                  </div>

                  <div class=""></div>

                  <section>
                    <div class="profileinfo">
                      <h3 class="profilename"><span class="data" data-paths="profile.firstName" id="el-100">#{firstName}</span> <span class="data" data-paths="profile.lastName" id="el-101">#{lastName}</span></h3>
                      <h4 class="profilelocation"><div class="kdview"><span class="data" data-paths="locationTags" id="el-109">#{if locationTags then locationTags[0] else 'Earth'}</span></div></h4>
                      <h5>
                        <a class="user-home-link" href="http://#{nickname}.koding.com" target="_blank">#{nickname}.koding.com</a>
                        <cite>member for #{if amountOfDays < 2 then 'a' else amountOfDays} day#{if amountOfDays > 1 then 's' else ''}.</cite>
                      </h5>
                      <div class="profilestats">
                        <div class="fers">
                          <a class="kdview" href="#"><cite></cite><span class="data" data-paths="counts.followers" id="el-93">#{counts.followers}</span> <span>Followers</span></a>
                        </div>
                        <div class="fing">
                          <a class="kdview" href="#"><cite></cite><span class="data" data-paths="counts.following" id="el-94">#{counts.following}</span> <span>Following</span></a>
                        </div>
                         <div class="liks">
                          <a class="kdview" href="#"><cite></cite><span class="data" data-paths="counts.likes" id="el-95">#{counts.likes}</span> <span>Likes</span></a>
                        </div>
                        <div class="contact">
                          <a class="" href="#"><cite></cite><span>Contact</span><span class="data" data-paths="profile.firstName" id="el-110">#{firstName}</span></a>
                        </div>
                      </div>

                      <div class="profilebio">
                        <p><span class="data" data-paths="profile.about" id="el-107">#{about}</span></p>
                      </div>
                      <div class="skilltags"><label>SKILLS</label><div class="tag-group"><div class="kdview listview-wrapper">...<div class="kdview kdscrollview"><div class="kdview kdlistview kdlistview-default skilltag-cloud"></div></div></div></div></div>
                    </div>
                  </section>
                </div>
                #{if not isLoggedIn then addHomeLinkBar() else ''}
                <div class="kdview kdsplitview kdsplitview-vertical lazy" style="height: 100%; width: 100%;">
                    <div class="kdview kdscrollview kdsplitview-panel panel-0 toggling" style="width: 139px; left: 0px;">
                        <div class="kdview common-inner-nav">
                            <div class="kdview listview-wrapper list">
                                <h4 class="kdview kdheaderview list-group-title">
                                    <span>FILTER</span>
                                </h4>
                                <ul class="kdview kdlistview kdlistview-default">
                                    <li class="kdview kdlistitemview kdlistitemview-default everything">
                                        <a href="#">Everything</a>
                                    </li>
                                    <li class="kdview kdlistitemview kdlistitemview-default statuses">
                                        <a href="#">Status Updates</a>
                                    </li>
                                    <li class="kdview kdlistitemview kdlistitemview-default codesnips">
                                        <a href="#">Code Snippets</a>
                                    </li>
                                </ul>
                            </div>
                            <div class="kdview listview-wrapper list">
                                <h4 class="kdview kdheaderview list-group-title">
                                    <span>SORT</span>
                                </h4>
                                <ul class="kdview kdlistview kdlistview-default">
                                    <li class="kdview kdlistitemview kdlistitemview-default sorts.likesCount">
                                        <a href="#">Most popular</a>
                                    </li>
                                    <li class="kdview kdlistitemview kdlistitemview-default modifiedAt">
                                        <a href="#">Latest activity</a>
                                    </li>
                                    <li class="kdview kdlistitemview kdlistitemview-default sorts.repliesCount">
                                        <a href="#">Most activity</a>
                                    </li>
                                </ul>
                            </div>
                            <div class="kdview help-box">
                                <div>
                                    <cite class="data" data-paths="title" id="el-614">NEED HELP?</cite> <a href="#"><span class="data" data-paths="subtitle" id="el-615">Learn Personal feed</span></a>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="kdview kdscrollview kdsplitview-panel panel-1 narrow" style="width: 100%; left: 139px;">
                        <div class="kdview feeder-tabs kdtabview">
                            <div class="kdview kdtabhandlecontainer hide-close-icons hidden">
                                <div class="kdtabhandle active" style="max-width: 128px;">
                                    <b>everything</b>
                                </div>
                                <div class="kdtabhandle" style="max-width: 128px;">
                                    <b>statuses</b>
                                </div>
                                <div class="kdtabhandle" style="max-width: 128px;">
                                    <b>codesnips</b>
                                </div>
                            </div>
                            <div class="kdview kdtabpaneview everything clearfix active">
                                <header class="kdview feeder-header clearfix">
                                    <p>
                                        Everything
                                    </p>
                                </header>
                                <div class="kdview listview-wrapper" style="height: 100%;">
                                    <div class="kdview kdscrollview">
                                        <div class="kdview kdlistview kdlistview-everything activity-related"></div>
                                        <div class="lazy-loader">
                                            Loading...<span class="kdview kdloader" style="width: 16px; height: 16px;"><span id="cl_kd-1275" class="canvas-loader" style="display: block;"><canvas width="16" height="16"></canvas><canvas style="display: none;" width="16" height="16"></canvas></span></span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

      </div>
    </section>
  </div>
    #{KONFIG.getConfigScriptTag {entryPoint: { slug : profile.nickname, type: "profile" }, roles:['guest'], permissions:[]}}
    #{getScripts()}
  </body>
  </html>
  """

addHomeLinkBar =->
  slug = 'koding'
  """
  <div class='screenshots'>
    <div class="home-links" id='home-login-bar'>
      <div class='overlay'></div>
      <a class="custom-link-view browse orange" href="#"><span class="icon"></span><span class="title">Learn more...</span></a><a class="custom-link-view join green" href="/#{slug}/Join"><span class="icon"></span><span class="title">Request an Invite</span></a><a class="custom-link-view register" href="/#{slug}/Register"><span class="icon"></span><span class="title">Register</span></a><a class="custom-link-view login" href="/#{slug}/Login"><span class="icon"></span><span class="title">Login</span></a>
    </div>
  </div>
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
  """

getDefaultUserContents =(firstName, lastName)->
  """
    <div class="content-item default-item" id='profile-blog-default-item'>
      <div class="title"><span class="text">Hello!</span></div>
      <div class="has-markdown"><span class="data">
        <p>
          #{firstName} #{lastName} has not written any Blog Posts yet. Click 'Activitiy' on top to see #{firstName}'s posts on Koding.</span></div>
        </p>
    </div>
  """