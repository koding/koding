do ->
  mainController = KD.getSingleton 'mainController'


  handleRoute =(groupId, route)->
    console.log 'invoking a route by group id...'

  notFound =(route)->
    KDRouter.addRoute route, ->
      console.warn "Contract warning: shared route #{route} is not implemented."

  routes =

    '/recover/:recoveryToken': ({recoveryToken})->
      mainController.appReady ->
        # TODO: DRY this one
        $('body').addClass 'login'
        mainController.loginScreen.show()
        mainController.loginScreen.$().css marginTop : 0
        mainController.loginScreen.hidden = no

        recoveryToken = decodeURIComponent recoveryToken
        KD.remote.api.JPasswordRecovery.validate recoveryToken, (err, isValid)->
          if err or !isValid
            new KDNotificationView
              title   : 'Something went wrong.'
              content : err?.message or """
                That doesn't seem to be a valid recovery token!
                """
          else
            {loginScreen} = mainController
            loginScreen.resetForm.addCustomData {recoveryToken}
            loginScreen.animateToForm "reset"
          location.replace '#'

    '/invitation/:inviteToken': ({inviteToken})->
      inviteToken = decodeURIComponent inviteToken
      if KD.isLoggedIn()
        new KDNotificationView
          title: 'Could not redeem invitation because you are already logged in.'
      else KD.remote.api.JInvitation.byCode inviteToken, (err, invite)->
        if err or !invite? or invite.status not in ['active','sent']
          if err then error err
          log invite
          new KDNotificationView
            title: 'Invalid invitation code!'
        else
          # TODO: DRY this one
          # $('body').addClass 'login'
          setTimeout ->
            new KDNotificationView
              cssClass  : "login"
              # type      : "mini"
              title     : "Great, you received an invite, taking you to the register form."
              # content   : "You received an invite, taking you to the register form!"
              duration  : 3000
            setTimeout ->
              mainController.loginScreen.slideDown =>
                mainController.loginScreen.animateToForm "register"
                mainController.propagateEvent KDEventType: 'InvitationReceived', invite
            , 3000
          , 2000
            # mainController.loginScreen.show()
            # mainController.loginScreen.$().css marginTop : 0
            # mainController.loginScreen.hidden = no
            # mainController.loginScreen.animateToForm 'register'
        location.replace '#'

    '/verify/:confirmationToken': ({confirmationToken})->
      confirmationToken = decodeURIComponent confirmationToken
      KD.remote.api.JEmailConfirmation.confirmByToken confirmationToken, (err)->
        location.replace '#'
        if err
          throw err
          new KDNotificationView
            title     : "Something went wrong, please try again later!"
        else
          new KDNotificationView
            title     : "Thanks for confirming your email address!"

    '/member/:username': ({username})->

        KD.remote.api.JAccount.one "profile.nickname" : username, (err, account)->
          if err then warn err
          else if account
            appManager.tell "Members", "createContentDisplay", account

    '/discussion/:title': ({title})->

        KD.remote.api.JDiscussion.one "title": title, (err, discussion)->
          if err then warn err
          else if discussion
            appManager.tell "Activity", "createContentDisplay", discussion

  sharedRoutes = KODING_ROUTES.concat KODING_ROUTES.map (route)->
    route.replace /^\/Groups\/:group/, ''

  notFound(route) for route in sharedRoutes when route not in Object.keys routes
  KDRouter.addRoutes routes
