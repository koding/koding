class LoginAppsController extends AppController

  handler = (callback)->-> KD.singleton('appManager').open 'Login', callback

  handleResetRoute = ({params:{token}})->
    do handler (app)=>
      if KD.isLoggedIn()
        KD.getSingleton('router').handleRoute "/Account/Profile?focus=password&token=#{token}"
      else
        app.getView().setCustomDataToForm('reset', {recoveryToken:token})
        app.getView().animateToForm('reset')

  KD.registerAppClass this,
    name                        : "Login"
    routes                      :
      '/:name?/Login'           : handler (app)-> app.getView().animateToForm 'login'
      '/:name?/Redeem'          : handler (app)-> app.getView().animateToForm 'redeem'
      '/:name?/Register'        : handler (app)-> app.getView().animateToForm 'register'
      '/:name?/Recover'         : handler (app)-> app.getView().animateToForm 'recover'
      '/:name?/Reset/:token'    : handleResetRoute
      '/:name?/ResendToken'     : handler (app)-> app.getView().animateToForm 'resendEmail'
    hiddenHandle                : yes
    behavior                    : 'application'
    preCondition                :
      condition                 : (options, cb)-> cb yes #not KD.isLoggedIn()
      failure                   : -> KD.getSingleton('router').handleRoute "/Activity"

  constructor:(options = {}, data)->

    options.view    = new LoginView
      testPath      : "landing-login"
    options.appInfo =
      name          : "Login"

    super options, data
