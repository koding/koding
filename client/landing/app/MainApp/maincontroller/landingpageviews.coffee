
class LandingPageSideBar extends KDView

  constructor:(isLoggedIn = no)->

    options     =
      lazyDomId : 'landing-page-sidebar'

    super options

    log "here I am...."

    @navController = new NavigationController
      view           : new NavigationList
        type         : "navigation"
        itemClass    : NavigationLink
      wrapper        : no
      scrollView     : no
    ,
      items : [
        { title : "Activity",       path : "/Activity" }
        { title : "Topics",         path : "/Topics" }
        { title : "Members",        path : "/Members" }
        { title : "Develop",        path : "/Develop", loggedIn: yes }
        { title : "Apps",           path : "/Apps" }
        { type  : "separator" }
        { title : "Invite Friends", type : "account", loggedIn: yes }
        { title : "Account",        path : "/Account", type : "account", loggedIn  : yes }
        { title : "Logout",         path : "/Logout",  type : "account", loggedIn  : yes, action : "logout" }
        { title : "Login",          path : "/Login",   type : "account", loggedOut : yes, action : "login" }
      ]

    @addSubView @nav = @navController.getView()

class LandingPageNavLink extends KDCustomHTMLView

  constructor:(options, data)->

    options.lazyDomId = 'landing-page-sidebar'
    options.partial   = \
      """
        <li class='#{options.cssClass or options.title}'>
          <a href='#{options.link or ""}'>
            <span class='icon'></span>#{options.title}
          </a>
        </li>
      """

    super

  click:(event)->
    {loginScreen} = @getSingleton 'mainController'
    {action} = @getOptions()

    action = 'login' unless KD.isLoggedIn()

    switch action
      when 'login'
        loginScreen.animateToForm 'login'
