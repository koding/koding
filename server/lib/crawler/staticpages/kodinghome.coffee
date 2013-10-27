module.exports = ->

  getStyles    = require './styleblock'
  getStyles  = require './styleblock'
  getGraphMeta  = require './graphmeta'

  """

  <!doctype html>
  <html lang="en" prefix="og: http://ogp.me/ns#"><head>
    <title>Koding</title>
    #{getStyles()}
    #{getGraphMeta()}
  <style type="text/css">@-webkit-keyframes rotate {
    from  { -webkit-transform: rotate(0deg); }
    to   { -webkit-transform: rotate(360deg); }
  }

  @keyframes rotate {
    from  { transform: rotate(0deg); }
    to   { transform: rotate(360deg); }
  }

  .dropbox-dropin-btn, .dropbox-dropin-btn:link, .dropbox-dropin-btn:hover {
    display: inline-block;
    height: 14px;
    font-family: "Lucida Grande", "Segoe UI", "Tahoma", "Helvetica Neue", "Helvetica", sans-serif;
    font-size: 11px;
    font-weight: 600;
    color: #636363;
    text-decoration: none;
    padding: 1px 7px 5px 3px;
    border: 1px solid #ebebeb;
    border-radius: 2px;
    border-bottom-color: #d4d4d4;
    background: #fcfcfc;
  background: -moz-linear-gradient(top, #fcfcfc 0%, #f5f5f5 100%);
  background: -webkit-linear-gradient(top, #fcfcfc 0%, #f5f5f5 100%);
  background: linear-gradient(to bottom, #fcfcfc 0%, #f5f5f5 100%);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#fcfcfc', endColorstr='#f5f5f5',GradientType=0);
  }

  .dropbox-dropin-default:hover, .dropbox-dropin-error:hover {
    border-color: #dedede;
    border-bottom-color: #cacaca;
    background: #fdfdfd;
  background: -moz-linear-gradient(top, #fdfdfd 0%, #f5f5f5 100%);
  background: -webkit-linear-gradient(top, #fdfdfd 0%, #f5f5f5 100%);
  background: linear-gradient(to bottom, #fdfdfd 0%, #f5f5f5 100%);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#fdfdfd', endColorstr='#f5f5f5',GradientType=0);
  }

  .dropbox-dropin-default:active, .dropbox-dropin-error:active {
    border-color: #d1d1d1;
    box-shadow: inset 0 1px 1px rgba(0,0,0,0.1);
  }

  .dropbox-dropin-btn .dropin-btn-status {
    display: inline-block;
    width: 15px;
    height: 14px;
    vertical-align: bottom;
    margin: 0 5px 0 2px;
    background: transparent url('https://www.dropbox.com/static/images/widgets/dbx-saver-status.png') no-repeat;
    position: relative;
    top: 2px;
  }

  .dropbox-dropin-default .dropin-btn-status {
    background-position: 0px 0px;
  }

  .dropbox-dropin-progress .dropin-btn-status {
    width: 18px;
    margin: 0 4px 0 0;
    background: url('https://www.dropbox.com/static/images/widgets/dbx-progress.png') no-repeat center center;
    -webkit-animation-name: rotate;
    -webkit-animation-duration: 1.7s;
    -webkit-animation-iteration-count: infinite;
    -webkit-animation-timing-function: linear;
    animation-name: rotate;
    animation-duration: 1.7s;
    animation-iteration-count: infinite;
    animation-timing-function: linear;
  }

  .dropbox-dropin-success .dropin-btn-status {
    background-position: -15px 0px;
  }

  .dropbox-dropin-disabled {
    background: #e0e0e0;
    border: 1px #dadada solid;
    border-bottom: 1px solid #ccc;
    box-shadow: none;
  }

  .dropbox-dropin-disabled .dropin-btn-status {
    background-position: -30px 0px;
  }

  .dropbox-dropin-error .dropin-btn-status {
    background-position: -45px 0px;
  }

  @media only screen and (-webkit-min-device-pixel-ratio: 1.4) {
    .dropbox-dropin-btn .dropin-btn-status {
      background-image: url('https://www.dropbox.com/static/images/widgets/dbx-saver-status-2x.png');
      background-size: 60px 14px;
      -webkit-background-size: 60px 14px;
    }

    .dropbox-dropin-progress .dropin-btn-status {
      background: url('https://www.dropbox.com/static/images/widgets/dbx-progress-2x.png') no-repeat center center;
      background-size: 20px 20px;
      -webkit-background-size: 20px 20px;
    }
  }

  .dropbox-saver:hover, .dropbox-chooser:hover {
    text-decoration: none;
    cursor: pointer;
  }

  .dropbox-chooser, .dropbox-dropin-btn {
    line-height: 11px !important;
    text-decoration: none !important;
    box-sizing: content-box !important;
    -webkit-box-sizing: content-box !important;
    -moz-box-sizing: content-box !important;
  }
  </style><script src="//d37gvrvc0wt4s1.cloudfront.net/js/1/rollbar.min.js" async=""></script><script type="text/javascript" charset="utf-8" async="" data-requirecontext="_" data-requiremodule="order" src="/js/order.js"></script><script type="text/javascript" charset="utf-8" data-requirecontext="_" data-requiremodule="/js/highlightjs/highlight.pack.js" src="/js/highlightjs/highlight.pack.js"></script><script type="text/javascript" charset="utf-8" data-requirecontext="_" data-requiremodule="/js/kd.995.js" src="/js/kd.995.js"></script><script type="text/javascript" charset="utf-8" data-requirecontext="_" data-requiremodule="/js/introapp.995.js" src="/js/introapp.995.js"></script><script type="text/javascript" charset="utf-8" data-requirecontext="_" data-requiremodule="/js/koding.995.js" src="/js/koding.995.js"></script><style></style></head>
  <body class="koding intro">

    <!--[if IE]>
    <script>(function(){window.location.href='/unsupported.html'})();</script>
    <![endif]-->

    <div class="kdview home" id="kdmaincontainer">
      <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden">...</div>
      <header class="kdview" id="main-header"><div class="kdview"><a id="koding-logo" class="" href="#"><span></span></a><a id="header-sign-in" class="custom-link-view" href="/Login"><span class="title" data-paths="title" id="el-75">Login</span></a></div></header>
    <section id="main-panel-wrapper" class="kdview" style="height: 271px;"><div id="sidebar-panel" class="kdview"><div id="sidebar" class="kdview"><div id="main-nav">
    <div class="avatar-placeholder">
      <div id="avatar-area">
        <div class="avatarview avatar-image-wrapper" title="View your public profile" style="width: 160px; height: 76px; background-image: url(https://www.koding.com/images/defaultavatar/default.avatar.160.png);"><cite></cite></div>
      </div>
    </div>
    <div class="kdview actions"><a class="notifications" title="Notifications" href="#"><span class="count">
    <cite></cite>
    <span class="arrow-wrap">
      <span class="arrow"></span>
    </span>
  </span>
  <span class="icon"></span></a>
  <a class="messages" title="Messages" href="#"><span class="count">
    <cite></cite>
    <span class="arrow-wrap">
      <span class="arrow"></span>
    </span>
  </span>
  <span class="icon"></span></a>
  <a class="group-switcher" title="Your groups" href="#"><span class="count">
    <cite></cite>
    <span class="arrow-wrap">
      <span class="arrow"></span>
    </span>
  </span>
  <span class="icon"></span></a></div>
    <div class="kdview kdlistview kdlistview-navigation"><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix"><a class="title" href="#"><span class="main-nav-icon transparent hidden"></span> <span class="main-nav-icon activity"></span> Activity</a></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix"><a class="title"><span class="main-nav-icon topics"></span>Topics</a></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix"><a class="title"><span class="main-nav-icon members"></span>Members</a></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix"><a class="title"><span class="main-nav-icon develop"></span>Develop</a></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix"><a class="kdview title"><span class="icon-top-badge hidden">0</span> <span class="main-nav-icon apps"></span> Apps</a></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator"><hr class=""></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account docs"><span class="title"><span class="main-nav-icon docs-jobs"></span> <a class="ext" href="http://koding.github.io/docs/" target="_blank">Docs</a> / <a class="ext" href="http://koding.github.io/jobs/" target="_blank">Jobs</a></span></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator"><hr class=""></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account"><a class="title"><span class="main-nav-icon login"></span>Login</a></div><div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account"><a class="title"><span class="main-nav-icon register"></span>Register</a></div></div>
    <div class="kdview kdlistview kdlistview-footer-menu"><div class="kdview kdlistitemview kdlistitemview-default help"><span class=""></span></div><div class="kdview kdlistitemview kdlistitemview-default about"><span class=""></span></div><div class="kdview kdlistitemview kdlistitemview-default chat"><span class=""></span></div></div>
  </div>
  <div id="finder-panel">
    <div id="finder-header-holder">
      <h2 class=""><span data-paths="profile.nickname" id="el-89">guest-286447</span>.kd.io</h2>
    </div>

    <div id="finder-dnduploader" class="kdview hidden"><div class="kdview file-droparea"><div class="file-drop">
    Drop files here!
    <small>/home/guest-286447/Uploads</small>
  </div></div></div>

    <div id="finder-holder" style="height: 47px;">
      <div class="kdview nfinder file-container"><div class="kdview kdscrollview jtreeview-wrapper"></div><div class="kdview no-vm-found-widget"><span class="kdview kdloader" style="width: 20px; height: 20px;"><span id="cl_kd-165" class="canvas-loader" style="display: none;"><canvas width="20" height="20"></canvas><canvas width="20" height="20" style="display: none;"></canvas></span></span>
  <div class="">There is no attached VM</div></div></div>
    </div>
  </div></div></div><div id="content-panel" class="kdview transition full" style="left: 0px; width: 100%;"><div id="main-tab-view" class="kdview kdscrollview kdtabview"></div><div id="main-tab-handle-holder" class="kdview kdtabhandlecontainer" style="width: 1280px;"><div class="kdtabhandle add-editor-menu visible-tab-handle plus first last"><span class="icon"></span><b class="hidden">Click here to start</b></div></div><button type="button" class="kdbutton app-settings-menu icon-only hidden" id="kd-142"><span class="icon"></span></button></div></section><div class="kdview notifications avatararea-popup"><div class="kdview tab"><span class="avatararea-popup-close"></span></div><div class="kdview content hidden"><div class="kdview sublink top hidden">You have no new notifications.</div><div class="kdview listview-wrapper"><div class="kdview kdscrollview" style="max-height: 89px;"><ul class="kdview kdlistview kdlistview-default avatararea-popup-list"></ul><div class="lazy-loader">Loading...<span class="kdview kdloader" style="width: 16px; height: 16px;"><span id="cl_kd-181" class="canvas-loader" style="display: block;"><canvas width="16" height="16"></canvas><canvas width="16" height="16" style="display: none;"></canvas></span></span></div></div></div><div class="kdview sublink"><a href="#">View all of your activity notifications...</a></div></div><div class="kdview content sublink">Login required to see notifications</div></div><div class="kdview messages avatararea-popup"><div class="kdview tab"><span class="avatararea-popup-close"></span></div><div class="kdview content hidden"><div class="kdview sublink top hidden">You have no new messages.</div><div class="kdview listview-wrapper"><div class="kdview kdscrollview" style="max-height: 89px;"><ul class="kdview kdlistview kdlistview-default avatararea-popup-list"></ul><div class="lazy-loader">Loading...<span class="kdview kdloader" style="width: 16px; height: 16px;"><span id="cl_kd-193" class="canvas-loader" style="display: block;"><canvas width="16" height="16"></canvas><canvas width="16" height="16" style="display: none;"></canvas></span></span></div></div></div><div class="kdview sublink"><a href="#">See all messages...</a></div></div><div class="kdview content sublink">Login required to see messages</div></div><div class="kdview group-switcher avatararea-popup"><div class="kdview tab"><span class="avatararea-popup-close"></span></div><div class="kdview content hidden" style=""><div class="kdview sublink top hidden">You have pending group invitations:</div><div class="kdview listview-wrapper"><div class="kdview kdscrollview"><ul class="kdview kdlistview kdlistview-default avatararea-popup-list"></ul><div class="lazy-loader">Loading...<span class="kdview kdloader" style="width: 16px; height: 16px;"><span id="cl_kd-208" class="canvas-loader" style="display: block;"><canvas width="16" height="16"></canvas><canvas width="16" height="16" style="display: none;"></canvas></span></span></div></div></div><div class="kdview sublink top">Switch to:<span class="icon help"></span></div><div class="kdview listview-wrapper"><div class="kdview kdscrollview" style="max-height: 89px;"><ul class="kdview kdlistview kdlistview-default avatararea-popup-list"></ul><div class="lazy-loader">Loading...<span class="kdview kdloader" style="width: 16px; height: 16px;"><span id="cl_kd-215" class="canvas-loader" style="display: block;"><canvas width="16" height="16"></canvas><canvas width="16" height="16" style="display: none;"></canvas></span></span></div></div></div><div id="avatararea-bottom-split-view" class="kdview kdsplitview kdsplitview-vertical" style="width: 278px;"><div class="kdview kdscrollview kdsplitview-panel panel-0" style="width: 130px; left: 0px;"><div class="kdview split sublink"></div></div><div class="kdview kdscrollview kdsplitview-panel panel-1" style="left: 130px; width: 148px;"><div class="kdview split sublink right"></div></div></div></div><div class="kdview content sublink">Login required to switch groups</div></div><div class="kdview main-chat-panel hidden"><div class="kdview main-chat-header"><button type="button" class="kdbutton panel-pinner icon-only" id="kd-241"><span class="icon left"></span></button>
  <h1 class="kdview kdheaderview header-view-section"><cite></cite> <span class="section-title">Conversations</span></h1>
  <button type="button" class="kdbutton clean-gray conversation-starter with-icon" id="kd-239">
    <span class="icon plus-black"></span>
    <span class="button-title"></span>
  </button></div><ul class="kdview kdlistview kdlistview-default chat-list"></ul><div class="kdview warning-widget">Conversations are under construction, you can still
  send and receive messages from other Koding users
  but these messages will not be saved.</div></div></div>

    <script type="text/javascript" async="" src="https://ssl.google-analytics.com/ga.js"></script><script type="text/javascript" async="" src="https://cdn.mxpnl.com/libs/mixpanel-2.2.min.js"></script><script>var KD = {"config":{"precompiledApi":true,"authExchange":"auth-995","github":{"clientId":"5891e574253e65ddb7ea"},"embedly":{"apiKey":"94991069fb354d4e8fdb825e52d4134a"},"userSitesDomain":"kd.io","useNeo4j":true,"logToExternal":true,"resourceName":"koding-social-995","suppressLogs":true,"version":"995","mainUri":"http://koding.com","broker":{"servicesEndpoint":"/-/services/broker","sockJS":"https://broker-995.koding.com/subscribe"},"apiUri":"https://www.koding.com","appsUri":"https://koding-apps.s3.amazonaws.com","uploadsUri":"https://koding-uploads.s3.amazonaws.com","sourceUri":"http://webserver-995a.sj.koding.com:1337","roles":["guest"],"permissions":[]}};</script>
    <script>

    console.time("Framework loaded");
    console.time("Koding.com loaded");

    var _rollbarParams = {
      "server.environment": "production",
      "client.javascript.source_map_enabled": true,
      "client.javascript.code_version": "995",
      "client.javascript.guess_uncaught_frames": true
    };
    _rollbarParams["notifier.snippet_version"] = "2"; var _rollbar=["713a5f6ab23c4ab0abc05494ef7bca55", _rollbarParams]; var _ratchet=_rollbar;
    (function(w,d){w.onerror=function(e,u,l){_rollbar.push({_t:'uncaught',e:e,u:u,l:l});};var i=function(){var s=d.createElement("script");var
    f=d.getElementsByTagName("script")[0];s.src="//d37gvrvc0wt4s1.cloudfront.net/js/1/rollbar.min.js";s.async=!0;
    f.parentNode.insertBefore(s,f);};if(w.addEventListener){w.addEventListener("load",i,!1);}else{w.attachEvent("onload",i);}})(window,document);
  </script>

  <script src="/js/require.js"></script>

  <script>
    require.config({baseUrl: "/js", waitSeconds:30});
    require(["order!/js/highlightjs/highlight.pack.js",
             "order!/js/kd.995.js",
             "order!/js/introapp.995.js",
             "order!/js/koding.995.js"]);
  </script>

  <script type="text/javascript">(function(e,b){if(!b.__SV){var a,f,i,g;window.mixpanel=b;a=e.createElement("script");a.type="text/javascript";a.async=!0;a.src=("https:"===e.location.protocol?"https:":"http:")+'//cdn.mxpnl.com/libs/mixpanel-2.2.min.js';f=e.getElementsByTagName("script")[0];f.parentNode.insertBefore(a,f);b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==
  typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");for(g=0;g<i.length;g++)f(c,i[g]);
  b._i.push([a,e,d])};b.__SV=1.2}})(document,window.mixpanel||[]);
  mixpanel.init("113c2731b47a5151f4be44ddd5af0e7a");</script>

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

  <script type="text/javascript" src="https://www.dropbox.com/static/api/1/dropins.js" id="dropboxjs" data-app-key="yzye39livlcc21j"></script>


  <div class="kdview intro-view in"><div class="kdview kd-slide" style="-webkit-user-select: none; -webkit-user-drag: none; -webkit-tap-highlight-color: rgba(0, 0, 0, 0); font-size: 20px;"><div class="kdview kd-page entryPage moveFromTop current"><div class="top-slogan">A new way for developers to work
  <div>Software development has finally evolved,<br> It's now social, in the browser and free!</div></div><div class="buttons"><button type="button" class="kdbutton email" id="kd-6"><i></i>Sign up <span>with email</span></button><button type="button" class="kdbutton github" id="kd-7"><i></i>Sign up <span>with gitHub</span></button></div></div><div class="kdview kd-page moveToBottom"><div class="slider-page">
    <div class="slogan"><span data-paths="slogan" id="el-0">for <span>You</span></span></div>
    <div class="wrapper">
      <figure>
        <img src="/images/homeslide/you.svg?1382834938126">
      </figure>
      <div class="details">
        <span data-paths="subSlogan" id="el-1"><p>
    You have great ideas.  You want to meet brilliant minds, and bring those ideas to life.  You want to start simple.  Maybe soon you'll have a 10 person team, commanding 100s of servers.
  </p>
  <p>
    You want to learn Python, Java, C, Go, Nodejs, HTML, CSS or Javascript or any other. Community will help you along the way.
  </p></span>
      </div>
    </div>
  </div></div><div class="kdview kd-page moveToBottom"><div class="slider-page">
    <div class="slogan"><span data-paths="slogan" id="el-2">for <span>Developers</span></span></div>
    <div class="wrapper">
      <figure>
        <img src="/images/homeslide/developers.svg?1382834938132">
      </figure>
      <div class="details">
        <span data-paths="subSlogan" id="el-3"><p>
    You can have an amazing VM that is better than your laptop.  It's connected to internet 100x faster.  You can share it with anyone you wish. Clone git repos.  Test and iterate on your code without breaking your setup.
  </p>
  <p>
    It's free. Koding is your new localhost, in the cloud.
  </p></span>
      </div>
    </div>
  </div></div><div class="kdview kd-page moveToBottom"><div class="slider-page">
    <div class="slogan"><span data-paths="slogan" id="el-4">for <span>Education</span></span></div>
    <div class="wrapper">
      <figure>
        <img src="/images/homeslide/education.svg?1382834938133">
      </figure>
      <div class="details">
        <span data-paths="subSlogan" id="el-5"><p>
    Create a group where your students enjoy the resources you provide to them. Make it private or invite-only.  Let them share, collaborate and submit their assignments together.  It doesn't matter if you have ten students, or ten thousand.  Scale from just one to hundreds of computers.
  </p>
  <p>
    Koding is your new classroom.
  </p></span>
      </div>
    </div>
  </div></div><div class="kdview kd-page moveToBottom"><div class="slider-page">
    <div class="slogan"><span data-paths="slogan" id="el-6">for <span>Business</span></span></div>
    <div class="wrapper">
      <figure>
        <img src="/images/homeslide/business.svg?1382834938134">
      </figure>
      <div class="details">
        <span data-paths="subSlogan" id="el-7"><p>
    When you hire someone, they can get up to speed in your development environment in 5 minutes—easily collaborating with others and contributing code.  All without sharing ssh keys or passwords.  Stop cc'ing your team; stop searching through old emails.
  </p>
  <p>
    Koding is your new workspace.
  </p></span>
      </div>
    </div>
  </div></div><div class="kdview kd-page moveToBottom"><div class="slider-page">
    <div class="slogan"><span data-paths="slogan" id="el-8">Pricing</span></div>
    <div class="wrapper">
      <figure>
        <img src="/images/homeslide/price.svg?1382834938136">
      </figure>
      <div class="details">
        <span data-paths="subSlogan" id="el-9"><p>
    You'll be able to buy more resources for your personal account or for accounts in your organization.
  </p>
  <p>
    Coming soon.
  </p></span>
      </div>
    </div>
  </div></div></div><div class="kdinput on-off multiple-choice bottom-menu small">
    <a href="#" name="Koding" class="multiple-choice-Koding active" title="Select Koding">Koding</a><a href="#" name="You" class="multiple-choice-You" title="Select You">You</a><a href="#" name="Developers" class="multiple-choice-Developers" title="Select Developers">Developers</a><a href="#" name="Education" class="multiple-choice-Education" title="Select Education">Education</a><a href="#" name="Business" class="multiple-choice-Business" title="Select Business">Business</a><a href="#" name="Pricing" class="multiple-choice-Pricing" title="Select Pricing">Pricing</a>
  <input class="hidden no-kdinput" name=""></div></div><div class="kdview kdscrollview hidden login-screen login" style="top: -322px;"><div class="flex-wrapper">
    <div class="login-box-header">
      <a class="betatag">beta</a>
      <div class="logo">Koding</div>
    </div>
    <div class="kdview login-options-holder log"><h3 class="kdview kdheaderview"><span>SIGN IN WITH:</span></h3><ul class="login-options"><li class="koding active">koding</li><li class="github undefined">github</li></ul></div>
    <div class="kdview login-options-holder reg"><ul class="login-options"><li class="koding active">koding</li><li class="github active undefined">github</li></ul></div>
    <div class="login-form-holder lf">
      <form class="kdformview login-form"><div><div class="kdview"><input name="username" type="text" class="kdinput text " placeholder="Enter Koding Username"><span class="validation-icon"></span></div></div>
  <div><div class="kdview"><input name="password" type="password" class="kdinput text " placeholder="Enter Koding Password"><span class="validation-icon"></span></div></div>
  <div><button type="submit" class="kdbutton koding-orange w-loader" id="kd-50"><span class="kdview kdloader hidden" style="width: 21px; height: 21px; position: absolute; left: 50%; top: 50%; margin-top: -10.5px; margin-left: -10.5px;"><span id="cl_kd-128" class="canvas-loader" style="display: none;"><canvas width="21" height="21"></canvas><canvas width="21" height="21" style="display: none;"></canvas></span></span>
    <span class="icon hidden"></span>
    <span class="button-title">SIGN IN</span>
  </button></div></form>
    </div>
    <div class="login-form-holder rf">
      <form class="kdformview login-form"><section class="main-part">
    <div><div class="kdview half-size"><input name="firstName" type="text" class="kdinput text " placeholder="Your first name"><span class="validation-icon"></span></div><div class="kdview half-size"><input name="lastName" type="text" class="kdinput text " placeholder="Your last name"><span class="validation-icon"></span></div></div>
    <div><div class="kdview"><input name="email" type="text" class="kdinput text " placeholder="Your email address"><span class="validation-icon"></span><span class="kdview input-loader kdloader hidden" style="width: 16px; height: 16px;"><span id="cl_kd-61" class="canvas-loader" style="display: none;"><canvas width="16" height="16"></canvas><canvas width="16" height="16" style="display: none;"></canvas></span></span></div><span class="avatarview hidden" href="/undefined" style="width: 20px; height: 20px; background-image: url(https://gravatar.com/avatar/7207a48aaa44b27de3a18fa0687aac89?size=20&amp;d=https%3A%2F%2Fwww.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.20.png);"><cite></cite></span></div>
    <div><div class="kdview"><input name="username" type="text" class="kdinput text " placeholder="Desired username"><span class="validation-icon"></span><span class="kdview input-loader kdloader hidden" style="width: 16px; height: 16px;"><span id="cl_kd-66" class="canvas-loader" style="display: none;"><canvas width="16" height="16"></canvas><canvas width="16" height="16" style="display: none;"></canvas></span></span></div></div>
    <div><div class="kdview"><input name="password" type="password" class="kdinput text " placeholder="Create a password"><span class="validation-icon"></span></div></div>
    <div><div class="kdview password-confirm"><input name="passwordConfirm" type="password" class="kdinput text " placeholder="Confirm your password"><span class="validation-icon"></span></div></div>
    <div class="invitation-field invited-by hidden">
      <span class="icon"></span>
      Invited by:
      <span class="wrapper"></span>
    </div>
  </section>
  <div><button type="submit" class="kdbutton koding-orange w-loader" id="kd-73"><span class="kdview kdloader hidden" style="width: 21px; height: 21px; position: absolute; left: 50%; top: 50%; margin-top: -10.5px; margin-left: -10.5px;"><span id="cl_kd-129" class="canvas-loader" style="display: none;"><canvas width="21" height="21"></canvas><canvas width="21" height="21" style="display: none;"></canvas></span></span>
    <span class="icon hidden"></span>
    <span class="button-title">REGISTER</span>
  </button></div>
  <div class="kdview hidden"><input name="inviteCode" type="hidden" class="kdinput hidden " value="" placeholder="" style=""><span class="validation-icon"></span></div>
  <section class="disabled-notice"><p>
  <b>REGISTRATIONS ARE CURRENTLY DISABLED</b>
  We're sorry for that, please follow us on <a href="http://twitter.com/koding" target="_blank">twitter</a>
  if you want to be notified when registrations are enabled again.
  </p></section></form>
    </div>
    <div class="login-form-holder rdf">
      <form class="kdformview login-form"><div><div class="kdview"><input name="inviteCode" type="text" class="kdinput text " placeholder="Enter your invite code"><span class="validation-icon"></span></div></div>
  <div><button type="submit" class="kdbutton koding-orange w-loader" id="kd-82"><span class="kdview kdloader hidden" style="width: 21px; height: 21px; position: absolute; left: 50%; top: 50%; margin-top: -10.5px; margin-left: -10.5px;"><span id="cl_kd-130" class="canvas-loader" style="display: none;"><canvas width="21" height="21"></canvas><canvas width="21" height="21" style="display: none;"></canvas></span></span>
    <span class="icon hidden"></span>
    <span class="button-title">Redeem</span>
  </button></div></form>
    </div>
    <div class="login-form-holder rcf">
      <form class="kdformview login-form"><div><div class="kdview"><input name="username-or-email" type="text" class="kdinput text " placeholder="Enter username or email"><span class="validation-icon"></span></div></div>
  <div><button type="submit" class="kdbutton koding-orange w-loader" id="kd-87"><span class="kdview kdloader hidden" style="width: 21px; height: 21px; position: absolute; left: 50%; top: 50%; margin-top: -10.5px; margin-left: -10.5px;"><span id="cl_kd-131" class="canvas-loader" style="display: none;"><canvas width="21" height="21"></canvas><canvas width="21" height="21" style="display: none;"></canvas></span></span>
    <span class="icon hidden"></span>
    <span class="button-title">RECOVER PASSWORD</span>
  </button></div></form>
    </div>
    <div class="login-form-holder rsf">
      <form class="kdformview login-form"><div class="login-hint">Set your new password below.</div>
  <div><div class="kdview"><input name="password" type="password" class="kdinput text " placeholder="Enter a new password"><span class="validation-icon"></span></div></div>
  <div><div class="kdview"><input name="passwordConfirm" type="password" class="kdinput text " placeholder="Confirm your password"><span class="validation-icon"></span></div></div>
  <div><button type="submit" class="kdbutton koding-orange w-loader" id="kd-100"><span class="kdview kdloader hidden" style="width: 21px; height: 21px; position: absolute; left: 50%; top: 50%; margin-top: -10.5px; margin-left: -10.5px;"><span id="cl_kd-132" class="canvas-loader" style="display: none;"><canvas width="21" height="21"></canvas><canvas width="21" height="21" style="display: none;"></canvas></span></span>
    <span class="icon hidden"></span>
    <span class="button-title">RESET PASSWORD</span>
  </button></div></form>
    </div>
    <div class="login-form-holder resend-confirmation-form">
      <form class="kdformview login-form"><div><div class="kdview"><input name="username-or-email" type="text" class="kdinput text " placeholder="Enter username or email"><span class="validation-icon"></span></div></div>
  <div><button type="submit" class="kdbutton koding-orange w-loader" id="kd-92"><span class="kdview kdloader hidden" style="width: 21px; height: 21px; position: absolute; left: 50%; top: 50%; margin-top: -10.5px; margin-left: -10.5px;"><span id="cl_kd-133" class="canvas-loader" style="display: none;"><canvas width="21" height="21"></canvas><canvas width="21" height="21" style="display: none;"></canvas></span></span>
    <span class="icon hidden"></span>
    <span class="button-title">RESEND CONFIRMATION EMAIL</span>
  </button></div></form>
    </div>
  </div>
  <div class="login-footer">
    <p class="regLink">Not a member? <a class="" href="#">Register an account</a></p>
    <p class="logLink">Already a member? <a class="" href="#">Go ahead and login</a></p>
    <p class="recLink">Trouble logging in? <a class="" href="#">Recover password</a></p>
    <p class="resend-confirmation-link">Didn't receive confirmation email? <a class="" href="#">Resend</a></p>
    <p><a href="/tos.html" target="_blank">Terms of service</a></p>
    <p><a href="/privacy.html" target="_blank">Privacy policy</a></p>
  </div></div></body></html>
  """
