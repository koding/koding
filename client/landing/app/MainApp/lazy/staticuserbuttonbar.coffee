class StaticUserButtonBar extends KDView
  constructor:(options,data)->
    super options,data

    @setClass 'user-button-bar'

    @ldc = @getSingleton 'lazyDomController'
    @mc  = @getSingleton 'mainController'

    @prefix =
      if @ldc.userEnteredFromGroup() and KD.config.groupEntryPoint isnt 'koding'
          "/#{KD.config.groupEntryPoint}"
      else ""

    @refreshButtons()
    @attachListeners()


  attachListeners:->
    @mc.on "accountChanged.to.*", => @refreshButtons()


  refreshButtons:->
    @destroySubViews()
    @addButtons()


  addButtons:->
    unless KD.isLoggedIn()
      @addLoginButton()
      @addRegisterButton()
    else
      @addLogoutButton()


  addLoginButton:->
    @addSubView @loginButton = new CustomLinkView
      title       : 'Login'
      cssClass    : 'login'
      icon        : {}
      click       : (event)=>
        event.preventDefault()
        @ldc.handleNavigationItemClick
          action  : 'login'
          path    : "#{@prefix}/Login"


  addLogoutButton:->
    @addSubView @logoutButton = new CustomLinkView
      title       : 'Logout'
      cssClass    : 'logout'
      icon        : {}
      click       : (event)=>
        event.preventDefault()
        @ldc.handleNavigationItemClick
          action  : 'logout'
          path    : "/Logout"


  addRegisterButton:->
    @addSubView @registerButton = new CustomLinkView
      title       : 'Register'
      cssClass    : 'register'
      icon        : {}
      click       : (event)=>
        event.preventDefault()
        @ldc.handleNavigationItemClick
          action  : 'register'
          path    : "#{@prefix}/Register"