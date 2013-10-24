module.exports = (account)->

  hash  = account.profile?.hash or ''
  bgImg = "//gravatar.com/avatar/#{hash}?size=160&d=#{encodeURIComponent '//images/defaultavatar/default.avatar.160.png'}"

  markup =
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
            <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix selected}">
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
            #{getSmallNavigation()}
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

  return markup

getSmallNavigation = ->
  """
  <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account promote">
    <a class="kdview title"><span class="main-nav-icon promote"></span><span>Up to 16GB free!</span></a>
  </div>
  <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account docs">
    <span class="title"><span class="main-nav-icon docs-jobs"></span><a class="ext" href="http://koding.github.io/docs/" target="_blank">Docs</a> / <a class="ext" href="http://koding.github.io/jobs/" target="_blank">Jobs</a></span>
  </div>
  <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account">
    <a class="title"><span class="main-nav-icon account"></span>Account</a>
  </div>
  <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix separator">
    <hr class="">
  </div>
  <div class="kdview kdlistitemview kdlistitemview-default navigation-item clearfix account">
    <a class="title"><span class="main-nav-icon logout"></span>Logout</a>
  </div>
  """
