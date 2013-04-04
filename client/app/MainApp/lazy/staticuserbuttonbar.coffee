class StaticUserButtonBar extends JView
  constructor:(options,data)->
    super options,data

    @setClass 'user-button-bar'

    @ldc = @getSingleton 'lazyDomController'
    @mc  = @getSingleton 'mainController'

    @buttonGroup = new KDView

    @refreshButtons()
    @attachListeners()


  attachListeners:->
    @mc.on "accountChanged.to.*", => @refreshButtons()


  refreshButtons:->
    @removeButtons()
    @addButtons()


  removeButtons:->
    @buttonGroup.removeSubView @loginButton
    @buttonGroup.removeSubView @logoutButton
    @buttonGroup.removeSubView @registerButton


  addButtons:->
    unless KD.isLoggedIn()
      @addLoginButton()
      @addRegisterButton()
    else
      @addLogoutButton()


  addLoginButton:->
    @buttonGroup.addSubView @loginButton = new KDButtonView
      title       : 'Login'
      cssClass    : 'clean-gray editor-button'
      callback    : =>
        @ldc.handleNavigationItemClick
          action  : 'login'
          path    : '/Login'


  addLogoutButton:->
    @buttonGroup.addSubView @logoutButton = new KDButtonView
      title       : 'Logout'
      cssClass    : 'clean-gray editor-button'
      callback    : =>
        @ldc.handleNavigationItemClick
          action  : 'logout'
          path    : '/Logout'


  addRegisterButton:->
    @buttonGroup.addSubView @registerButton = new KDButtonView
      title       : 'Register'
      cssClass    : 'clean-gray editor-button'
      callback    : =>
        @ldc.handleNavigationItemClick
          action  : 'register'
          path    : '/Register'


  pistachio:->
    """
    {{> @buttonGroup}}
    """