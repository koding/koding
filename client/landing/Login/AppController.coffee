class LoginAppsController extends AppController

  KD.registerAppClass this,
    name         : "Login"
    route        : [
      '/:name?/Login'
      '/:name?/Redeem'
      '/:name?/Register'
      '/:name?/Recover'
      '/:name?/ResendToken'
    ]
    hiddenHandle : yes
    labels       : ['Redeem', 'Register', 'Recover', 'ResendToken']
    preCondition :
      condition  : (options, cb)-> cb not KD.isLoggedIn()
      failure    : -> KD.getSingleton('router').handleRoute "/Activity"

  constructor:(options = {}, data)->

    options.view    = new LoginView
      testPath      : "landing-login"
    options.appInfo =
      name          : "Login"

    super options, data

  appIsShown: (params)->
    @handleRoute "/#{params.label}"

  handleQuery: ->
    {currentPath} = KD.getSingleton 'router'
    @handleRoute currentPath

  handleRoute: (route)->
    form = 'login'
    s = (exp, tf)-> if route.match exp then form = tf
    s /\/Login$/       , 'login'
    s /\/Redeem$/      , 'redeem'
    s /\/Register$/    , 'register'
    s /\/Recover$/     , 'recover'
    s /\/ResendToken$/ , 'resendEmail'

    @utils.defer =>
      @getView().animateToForm form