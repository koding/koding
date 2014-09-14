do ->

  handler = (callback)->->
    unless KD.isLoggedIn()
      KD.singleton('appManager').open 'Login', (app)-> callback app
    else
      KD.getSingleton('router').handleRoute "/Activity"

  handleResetRoute = ({params:{token}}) ->
    {appManager} = KD.singletons
    appManager.require 'Login', (app) ->
      if KD.isLoggedIn()
        KD.remote.api.JUser.fetchUser (err, user)->
          if user and user.passwordStatus is "valid"
            KD.getSingleton('router').handleRoute "/Activity"
          else
            KD.getSingleton('router').handleRoute "/Account/Profile?focus=password&token=#{token}"
      else
        appManager.open 'Login', ->
          app.getView().setCustomDataToForm('reset', {recoveryToken:token})
          app.getView().animateToForm('reset')

  handleVerifyRoute = ({params:{token}})->
    router = KD.getSingleton 'router'
    return router.handleRoute "/Login"  unless token
    KD.singleton('appManager').open 'Login', (app) ->
      KD.remote.api.JPasswordRecovery.validate token, (err, isValid)=>
        return KD.notify_ err.message  if err
        if isValid
          KD.notify_ "Thanks for confirming your email address"
          router.handleRoute "/Login"
        else
          KD.notify_ "Token is not valid"
          router.handleRoute "/Login"

  handleRedeemRoute = ({params:{name, token}})->
    token = decodeURIComponent token
    KD.remote.api.JInvitation.byCode token, (err, invite)->
      return callback err if err
      if KD.isLoggedIn()
        KD.remote.cacheable invite.group, (err, [group])->
          group.redeemInvitation token, (err)->
            if err
              KD.notify_ err.message or err
              return window.location.href = "/"

            new KDNotificationView
              title : 'Success!'
              type  : 'tray'

            KD.getSingleton('router').handleRoute "/#{group.slug}"
            KD.getSingleton('mainController').accountChanged KD.whoami()
      else
        if err or !invite? or invite.status not in ['active','sent']
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

  handleRecovery = ->
    KD.singleton('appManager').open 'Login', (app)->
      app.getView().animateToForm 'recover'

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

  KD.registerRoutes 'Login',
    '/:name?/Login/:token?'    : handler (app)-> app.getView().animateToForm 'login'
    '/:name?/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
    '/:name?/Register'         : handler (app)-> app.getView().animateToForm 'register'
    '/:name?/Register/:token'  : handleFinishRegistration
    '/:name?/Recover'          : handleRecovery
    '/:name?/Reset'            : handler (app)-> app.getView().animateToForm 'reset'
    '/:name?/Reset/:token'     : handleResetRoute
    '/:name?/Confirm/:token'   : handleResetRoute
    '/:name?/Verify/:token?'   : handleVerifyRoute
    '/:name?/Redeem/:token'    : handleRedeemRoute
    '/:name?/ResendToken'      : handler (app)-> app.getView().animateToForm 'resendEmail'
    #'/:name?/Login/:token?'    : handleRestriction (app)->
        #handler (app)-> app.getView().animateToForm 'login'
