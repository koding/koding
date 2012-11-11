class KodingRouter extends KDRouter

  constructor:-> super getRoutes.call this

  handleRoute =(groupId, route)->
    console.log 'invoking a route by group id...'

  notFound =(route)->
    # defer this so that notFound can be called before the constructor.
    @utils.defer => @addRoute route, ->
      console.warn "Contract warning: shared route #{route} is not implemented."

  handleRoot =->
    KD.getSingleton("contentDisplayController").hideAllContentDisplays()
    #appManager.openApplication null

  go =(app, group, rest...)->
    unless group?
      appManager.openApplication app
    else
      appManager.tell app, 'setGroup', group

  getRoutes =->
    mainController = KD.getSingleton 'mainController'
    
    routes =

      '/' : handleRoot
      ''  : handleRoot

      '/:name?/Groups'     : ({name})->  go 'Groups'    , name
      '/:name?/Activity'   : ({name})->  go 'Activity'  , name
      '/:name?/Members'    : ({name})->  go 'Members'   , name
      '/:name?/Topics'     : ({name})->  go 'Topics'    , name
      '/:name?/Develop'    : ({name})->  go 'StartTab'  , name
      '/:name?/Apps'       : ({name})->  go 'Apps'      , name

      '/:name?/Topics/:topicSlug': ({name, topicSlug}, state)->
        appManager.tell 'Topics', 'setGroup', name  if name?
        if state?
          appManager.tell 'Topics', 'createContentDisplay', state
        else
          console.log 'no state object was provided.'

      '/:name?/Activity/:activitySlug': ({name, activitySlug}, state)->
        appManager.tell 'Activity', 'setGroup', name  if name?
        if state?
          appManager.tell 'Activity', 'createContentDisplay', state
        else
          console.log 'no state object was provided.'

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

      '/:name': (params)->
        KD.remote.cacheable params.name, (err, model, name)->
          switch name?.constructorName
            when 'JAccount'
              appManager.tell 'Members', 'createContentDisplay', model
            when 'JGroup'
              appManager.tell 'Groups', 'createContentDisplay', model
            when 'JTopic'
              appManager.tell 'Topics', 'createContentDisplay', model
            else log "404 - /#{params.name}"

    sharedRoutes = KODING_ROUTES.concat KODING_ROUTES.map (route)->
      route.replace /^\/Groups\/:group/, ''

    for route in sharedRoutes when route not in Object.keys routes
      notFound.call this, route

    routes