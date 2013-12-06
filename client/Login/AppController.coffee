class LoginAppsController extends AppController

  handler = (callback)->
    ({params})->
      unless KD.isLoggedIn()
        KD.singleton('appManager').open 'Login', (app)-> callback app, params
      else
        KD.getSingleton('router').handleRoute "/Activity"

  handleResetRoute = ({params:{token}})->
    KD.singleton('appManager').open 'Login', (app)=>
      if KD.isLoggedIn()
        KD.getSingleton('router').handleRoute "/Account/Profile?focus=password&token=#{token}"
      else
        app.getView().setCustomDataToForm('reset', {recoveryToken:token})
        app.getView().animateToForm('reset')

  handleFailureOfRestriction =->
    KD.utils.defer -> new KDNotificationView title: "Login restricted"

  handleRestriction = (handler) ->
    ({params: {token : token }})->
      return handleFailureOfRestriction()  unless token

      KD.remote.api.JInvitation.byCode token, (err, invite)->
        if err or !invite?
          return handleFailureOfRestriction()  unless token

        do handler()

  KD.registerAppClass this,
    name                         : "Login"
    routes                       :
      '/:name?/Login/:token?'    : handleRestriction (app)->
          handler (app)-> app.getView().animateToForm 'register'
      '/:name?/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
      '/:name?/Register/:token?' : handleRestriction (app)->
          handler (app)-> app.getView().animateToForm 'register'
      '/:name?/Recover'          : handler (app)-> app.getView().animateToForm 'recover'
      '/:name?/Reset'            : handler (app)-> app.getView().animateToForm 'reset'
      '/:name?/Reset/:token'     : handleResetRoute
      '/:name?/ResendToken'      : handler (app)-> app.getView().animateToForm 'resendEmail'
    hiddenHandle                 : yes
    behavior                     : 'application'
    # removed preCondition because Reset can be called while
    # current user logged-in status

  constructor:(options = {}, data)->

    options.view    = new LoginView
      testPath      : "landing-login"
    options.appInfo =
      name          : "Login"

    super options, data
