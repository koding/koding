class LoginAppsController extends AppController

  handler = (callback)->-> KD.singleton('appManager').open 'Login', callback

  KD.registerAppClass this,
    name                    : "Login"
    routes                  :
      '/:name?/Login'       : handler (app)-> app.getView().animateToForm 'login'
      '/:name?/Redeem'      : handler (app)-> app.getView().animateToForm 'redeem'
      '/:name?/Register'    : handler (app)-> app.getView().animateToForm 'register'
      '/:name?/Recover'     : handler (app)-> app.getView().animateToForm 'recover'
      '/:name?/ResendToken' : handler (app)-> app.getView().animateToForm 'resendEmail'
    hiddenHandle            : yes
    behavior                : 'application'
    preCondition            :
      condition             : (options, cb)-> cb not KD.isLoggedIn()
      failure               : -> KD.getSingleton('router').handleRoute "/Activity"

  constructor:(options = {}, data)->

    options.view    = new LoginView
      testPath      : "landing-login"
    options.appInfo =
      name          : "Login"

    super options, data
