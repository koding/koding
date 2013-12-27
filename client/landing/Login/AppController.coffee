class LoginAppsController extends AppController

  handler = (callback)->->
    unless KD.isLoggedIn()
      KD.singleton('appManager').open 'Login', (app)-> callback app
    else
      KD.getSingleton('router').handleRoute "/Activity"

  handleResetRoute = ({params:{token}})->
    KD.singleton('appManager').open 'Login', (app) ->
      if KD.isLoggedIn()
        KD.getSingleton('router').handleRoute "/Activity"
      else
        app.getView().setCustomDataToForm('reset', {recoveryToken:token})
        app.getView().animateToForm('reset')

  handleRedeemRoute = ({params:{name, token}})->
    console.log "name: ", name
    token = decodeURIComponent token
    if KD.isLoggedIn()
      KD.remote.cacheable groupName, (err, [group])=>
        group.redeemInvitation token, (err)=>
          return KD.notify_ err.message or err  if err
          KD.notify_ 'Success!'
          console.log "will be routed to: ", "/#{groupName}/Activity"
          KD.getSingleton('router').handleRoute "/#{groupName}"
          KD.getSingleton('mainController').accountChanged KD.whoami()
    else KD.remote.api.JInvitation.byCode token, (err, invite)=>
      if err or !invite? or invite.status not in ['active','sent']
        unless KD.isLoggedIn()
          if err then error err
          KD.singleton('appManager').open 'Login', (app) ->
            new KDNotificationView
              title: 'Invalid invitation code!'
            app.getView().animateToForm 'login'
      else
        KD.singleton('appManager').open 'Login', (app) ->
          app.getView().animateToForm 'login'
          app.headBannerShowInvitation invite

  handleFinishRegistration = ({params:{token}}) ->
    KD.singleton('appManager').open 'Login', (app) ->
      app.prepareFinishRegistrationForm token  unless KD.isLoggedIn()

#  handleFailureOfRestriction =->
#    KD.utils.defer -> new KDNotificationView title: "Login restricted"

#  handleRestriction = (handler) ->
#    ({params: {token : token }})->
#      for url in [
#        'http:\/\/localhost'
#        'https:\/\/koding.com'
#      ] when 0 is window.location.href.indexOf url
#        return do handler()

#      return handleFailureOfRestriction()  unless token

#      KD.remote.api.JInvitation.byCodeForBeta token, (err, invite)->
#        if err or !invite?
#          return handleFailureOfRestriction()

#        do handler()

  KD.registerAppClass this,
    name                         : "Login"
    routes                       :
      #'/:name?/Login/:token?'    : handleRestriction (app)->
          #handler (app)-> app.getView().animateToForm 'login'
      '/:name?/Login/:token?'    : handler (app)-> app.getView().animateToForm 'login'
      '/:name?/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
      '/:name?/Register/:token?' : handler (app)-> app.getView().animateToForm 'register'
      '/:name?/Recover'          : handler (app)-> app.getView().animateToForm 'recover'
      '/:name?/Reset'            : handler (app)-> app.getView().animateToForm 'reset'
      '/:name?/Reset/:token'     : handleResetRoute
      '/:name?/Confirm/:token'   : handleResetRoute
      '/:name?/Redeem/:token'    : handleRedeemRoute
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

  headBannerShowInvitation:(invite)->
    view = @getView()
    view.headBannerShowInvitation invite

