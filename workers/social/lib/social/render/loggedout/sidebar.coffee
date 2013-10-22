module.exports = (account)->

  bgImg  = encodeURIComponent "//images/defaultavatar/default.avatar.160.png"

  """
  <div class="kdview" id="sidebar-panel">
    <div class="kdview" id="sidebar">
      <div id="main-nav">
        <div class="avatar-placeholder">
          <div id="avatar-area">
            <div class="avatarview avatar-image-wrapper" style="width: 160px; height: 76px; background-image: url(#{bgImg});"></div>
          </div>
        </div>
        <div class="kdview actions">
          <a class="notifications" href="#"><span class="count"><cite>0</cite></span><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
          <a class="messages" href="#"><span class="count"><cite>0</cite></span><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
          <a class="group-switcher" href="#"><span class="count"><cite>0</cite><span class="arrow-wrap"><span class="arrow"></span></span></span><span class="icon"></span></a>
        </div>
        <div class="kdview kdlistview kdlistview-navigation">
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
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
            <a class="title"><span class="main-nav-icon develop"></span>Develop</a>
          </div>
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix">
            <a class="title"><span class="main-nav-icon apps"></span>Apps</a>
          </div>
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator">
            <hr class="">
          </div>
          <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account">
            <a class="title"><span class="main-nav-icon login"></span>Login</a>
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
  """
