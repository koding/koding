class LoginAppsController extends AppController

  handler = (callback)->->
    unless KD.isLoggedIn()
      KD.singleton('appManager').open 'Login', (app)-> callback app
    else
      KD.getSingleton('router').handleRoute "/Activity"

  handleResetRoute = ({params:{token}})->
    KD.singleton('appManager').open 'Login', (app) ->
      if KD.isLoggedIn()
        KD.getSingleton('router').handleRoute "/Account/Profile?focus=password&token=#{token}"
      else
        app.getView().setCustomDataToForm('reset', {recoveryToken:token})
        app.getView().animateToForm('reset')

  handleFinishRegistration = ({params:{token}}) ->
    KD.singleton('appManager').open 'Login', (app) ->
      if KD.isLoggedIn()
        # TODO: is this case important for us to handle? C.T.
        KD.getSingleton('router').handleRoute '/'
      else
        app.prepareFinishRegistrationForm token

  handleFailureOfRestriction =->
    KD.utils.defer -> new KDNotificationView title: "Login restricted"

  handleRestriction = (handler) ->
    ({params: {token : token }})->
      for url in [
        'http:\/\/localhost'
        'https:\/\/koding.com'
      ] when 0 is window.location.href.indexOf url
        return do handler()

      return handleFailureOfRestriction()  unless token

      KD.remote.api.JInvitation.byCodeForBeta token, (err, invite)->
        if err or !invite?
          return handleFailureOfRestriction()  unless token

        do handler()

  KD.registerAppClass this,
    name                         : "Login"
    routes                       :
      '/:name?/Login/:token?'    : handleRestriction (app)->
          handler (app)-> app.getView().animateToForm 'login'
      '/:name?/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
      '/:name?/Register/:token?' : handleRestriction (app)->
          handler (app)-> app.getView().animateToForm 'register'
      '/:name?/Register2/:token' : handleFinishRegistration
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

  prepareFinishRegistrationForm: (token) ->
    { JPasswordRecovery } = KD.remote.api
    JPasswordRecovery.fetchRegistrationDetails token, (err, details) =>
      return  if KD.showError err

      view = @getView()
      view.finishRegistrationForm.setRegistrationDetails details
      view.setCustomDataToForm 'finishRegistration', recoveryToken: token
      view.animateToForm 'finishRegistration'
