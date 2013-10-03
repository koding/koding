module.exports = ->

  getHomeIntro = require './../homeintro'
  getStyles    = require './../styleblock'
  getScripts   = require './../scriptblock'
  getSidebar   = require './sidebar'

  """

  <!doctype html>
  <html lang="en">
  <head>
    <title>Koding</title>
    #{getStyles()}
  </head>
  <body class='koding'>

    <!--[if IE]>
    <script>(function(){window.location.href='/unsupported.html'})();</script>
    <![endif]-->

    <div class="kdview home" id="kdmaincontainer">
      <div id="invite-recovery-notification-bar" class="invite-recovery-notification-bar hidden"></div>
      <header class="kdview" id='main-header'>
        <div class="kdview">
          <a id="koding-logo" href="#" class='large'><span></span></a>
          <a id="header-sign-in" class="custom-link-view login" href="#!/Login"><span class="title" data-paths="title">Already a user? Sign In.</span><span class="icon"></span></a>
        </div>
      </header>
      #{getHomeIntro()}
      <section class="kdview" id="main-panel-wrapper">
        #{getSidebar()}
        <div class="kdview transition no-shadow full" id="content-panel" style="left: 0px; width: 1280px;">
        <div class="kdview kdscrollview kdtabview" id="main-tab-view">
          <div id="maintabpane-home" class="kdview content-area-pane activity content-area-new-tab-pane clearfix kdtabpaneview home active">
            <div id="content-page-home" class="kdview content-page home kdscrollview extra-wide"><section class="slider-section" id="slider-section">
  <div class="home-slider"><div id="you-page" class="slider-page active"><div class="wrapper">
  <figure></figure>
  <h3>
    <i></i> Koding for <span>You</span>
  </h3>
  <p>
    Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
  </p>
  <p>
    Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
  </p>
</div></div><div id="developers-page" class="slider-page"><div class="wrapper">
  <figure></figure>
  <h3>
    <i></i> Koding for <span>Developers</span>
  </h3>
  <p>
    Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
  </p>
  <p>
    Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
  </p>
</div></div><div id="education-page" class="slider-page"><div class="wrapper">
  <figure></figure>
  <h3>
    <i></i> Koding for <span>Education</span>
  </h3>
  <p>
    Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
  </p>
  <p>
    Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
  </p>
</div></div><div id="business-page" class="slider-page"><div class="wrapper">
  <figure></figure>
  <h3>
    <i></i> Koding for <span>Business</span>
  </h3>
  <p>
    Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
  </p>
  <p>
    Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
  </p>
</div></div><nav class="slider-nav"><a class="custom-link-view active" href="#"><span class="title" data-paths="title" id="el-94">You</span></a><a class="custom-link-view" href="#"><span class="title" data-paths="title" id="el-95">Developers</span></a><a class="custom-link-view" href="#"><span class="title" data-paths="title" id="el-96">Education</span></a><a class="custom-link-view" href="#"><span class="title" data-paths="title" id="el-97">Business</span></a></nav></div>
</section>
<section class="pricing-section" id="pricing-section">
  <h3>Simple Pricing</h3>
  <h4>Try it and see if it's really as cool as we say</h4>
  <div class="price-boxes">
    <a href="#" class="free">
      <span>Your first VM</span>
      Free
    </a>
    <a href="#" class="paid">
      <span>Each additional VM</span>
      $3 / Month
    </a>
  </div>
  <div class="pricing-details">
    <span><strong>Always on*</strong> $4 / Month</span>
    <span><strong>Extra RAM</strong> $3 / GB / Month</span><br>
    <span><strong>Extra Disk Space</strong> $2 / GB / Month</span>
    <span><strong>FireWall / Network Rules</strong> $2 / GB / Month</span>
  </div>
  <span class="pricing-contact"><a href="#">Contact us</a> for Education and Business pricing</span>
</section>
<footer class="home-footer">
</footer></div>
          </div>
        </div>
      <div id="main-tab-handle-holder" class="kdview kdtabhandlecontainer" style="width: 1280px;"><div class="kdtabhandle add-editor-menu visible-tab-handle plus first last"><span class="icon"></span><b class="">Click here to start</b></div><div title="Home" class="kdtabhandle  hidden kddraggable active" style="max-width: 128px;"><span class="close-tab"></span><b>Home</b></div></div><button type="button" class="kdbutton app-settings-menu icon-only hidden" id="kd-127"><span class="icon"></span></button></div>
      </section>
    </div>

  #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
  #{getScripts()}
  </body>
  </html>
  """