
class LandingPageSideBar extends KDView

  constructor:(isLoggedIn = no)->

    options     =
      lazyDomId : 'landing-page-sidebar'

    super options

    log "here I am...."

    @navController = new NavigationController
      view         : new NavigationList
        itemClass  : LandingPageNavigationLink
        type       : "navigation"
      scrollView   : no
      wrapper      : no
    ,
      items : [
        { title : "Request To Join", action : "request" }
        { title : "Register", loggedIn  : no,  action : "register" }
        { type  : "separator" }
        { title : "Logout",   loggedIn  : yes, action : "logout" }
        { title : "Login",    loggedOut : yes, action : "login" }
      ]

    @addSubView @nav = @navController.getView()

class LandingPageNavigationLink extends KDListItemView

  constructor:(options = {},data)->

    data.type      or= ""
    options.cssClass = KD.utils.curryCssClass "navigation-item clearfix account"#, data.type

    super options,data

    @name = data.title

  click:(event)->
    {action, appPath, title, path, type} = @getData()
    log "here", @getData()

    {loginScreen} = @getSingleton 'mainController'

    switch action
      when 'login'
        loginScreen.animateToForm 'login'
      when 'register'
        loginScreen.animateToForm 'register'
      when 'request'
        loginScreen.animateToForm 'lr'

  partial:(data)->
    "<a class='title'><span class='main-nav-icon #{@utils.slugify data.title}'></span>#{data.title}</a>"
