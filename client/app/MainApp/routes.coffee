do ->
  mainController = KD.getSingleton 'mainController'

  KDRouter.addRoutes
    #'/debug/:mode': ({mode})->
    #   mode = decodeURIComponent mode
    #   KD.debugStates[mode] = yes
  
    '/recover/:recoveryToken': ({recoveryToken})->
      mainController.appReady ->
        # TODO: DRY this one
        $('body').addClass 'login'
        mainController.loginScreen.show()
        mainController.loginScreen.$().css marginTop : 0
        mainController.loginScreen.hidden = no
        
        recoveryToken = decodeURIComponent recoveryToken
        bongo.api.JPasswordRecovery.validate recoveryToken, (err, isValid)->
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
      else bongo.api.JInvitation.byCode inviteToken, (err, invite)->
        debugger
        if err or !invite? or invite.status isnt 'active'
          new KDNotificationView
            title: 'Invalid invitation code!'
        else
          # TODO: DRY this one
          $('body').addClass 'login'
          mainController.loginScreen.show()
          mainController.loginScreen.$().css marginTop : 0
          mainController.loginScreen.hidden = no
          mainController.loginScreen.animateToForm 'register'
          mainController.propagateEvent KDEventType: 'InvitationReceived', invite
        location.replace '#'
    
    '/verify/:confirmationToken': ({confirmationToken})->
      confirmationToken = decodeURIComponent confirmationToken
      bongo.api.JEmailConfirmation.confirmByToken confirmationToken, (err)->
        throw err if err
        location.replace '#'