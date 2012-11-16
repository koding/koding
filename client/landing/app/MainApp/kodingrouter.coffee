class KodingRouter extends KDRouter

  constructor:(defaultRoute)->
    console.log 'default route', defaultRoute
    @openRoutes = {}
    @openRoutesById = {}
    KD.getSingleton('contentDisplayController')
      .on 'ContentDisplayIsDestroyed', @cleanupRoute.bind @
    super getRoutes.call this

    @on 'AlreadyHere', ->
      new KDNotificationView title: "You're already here!"
      console.trace()

  cleanupRoute:(contentDisplay)->
    delete @openRoutes[@openRoutesById[contentDisplay.id]]

  handleRoute =(groupId, route)->
    console.log 'invoking a route by group id...'

  notFound =(route)->
    # defer this so that notFound can be called before the constructor.
    @utils.defer => @addRoute route, ->
      console.warn "Contract warning: shared route #{route} is not implemented."

  handleRoot =->
    KD.getSingleton("contentDisplayController").hideAllContentDisplays()
    if KD.isLoggedIn()
      @handleRoute @getDefaultRoute(), replaceState: yes
    else
      KD.getSingleton('mainController').doGoHome()
  
  go =(app, group, rest...)->
    unless group?
      appManager.openApplication app
    else
      appManager.tell app, 'setGroup', group

  stripTemplate =(str, konstructor)->
    {slugTemplate} = konstructor
    slugRe = /^(.+)?(#\{slug\})(.+)?$/
    re = RegExp slugTemplate.replace slugRe, (tmp, begin, slug, end)->
      "^#{begin ? ''}(.*)#{end ? ''}$"
    str.match(re)?[1]

  handleNotFound:(route)->

    status_404 = =>
      KDRouter::handleNotFound.call @, route

    status_301 = (redirectTarget)=>
      @handleRoute "/#{redirectTarget}", replaceState: yes

    KD.remote.api.JUrlAlias.resolve route, (err, target)->
      if err or not target? then status_404()
      else status_301 target

  getDefaultRoute:-> '/Activity'

  openContent:(name, section, state, route)->
    appManager.tell section, 'createContentDisplay', state, (contentDisplay)=>
      @openRoutes[route] = contentDisplay
      @openRoutesById[contentDisplay.id] = route

  loadContent:(name, section, slug, route)->
    KD.remote.api.JName.one {name: route}, (err, name)=>
      if err
        new KDNotificationView title: err?.message or 'An unknown error has occured.'
      else if name?
        {constructorName, usedAsPath} = name
        selector = {}
        konstructor = KD.remote.api[constructorName]
        slug = stripTemplate route, konstructor
        selector[usedAsPath] = slug
        konstructor?.one selector, (err, model)=>
          @openContent name, section, model, route
      else
        @handleNotFound route
    #konstructor = KD.getContentConstructor section
    # appManager.tell section, 'createContentDisplay', state, (contentDisplay)=>
    #   @openRoutes[route] = contentDisplay
    #   @openRoutesById[contentDisplay.id] = route

  createContentDisplayHandler:(section)->
    ({name, topicSlug}, state, route)->
      contentDisplay = @openRoutes[route]
      if contentDisplay?
        KD.getSingleton("contentDisplayController")
          .hideAllContentDisplays contentDisplay
      else
        appManager.tell section, 'setGroup', name  if name?
        if state?
          @openContent name, section, state, route
        else
          @loadContent name, section, topicSlug, route

  getRoutes =->
    mainController = KD.getSingleton 'mainController'
    
    routes =

      '/' : handleRoot
      ''  : handleRoot

      # verbs
      '/:name?/Login'     : ({name})-> mainController.doLogin name
      '/:name?/Logout'    : ({name})-> mainController.doLogout name; @clear()
      '/:name?/Register'  : ({name})-> mainController.doRegister name
      '/:name?/Join'      : ({name})-> mainController.doJoin name
      '/:name?/Recover'   : ({name})-> mainController.doRecover name

      # nouns
      '/:name?/Groups'    : ({name})-> go 'Groups'    , name
      '/:name?/Activity'  : ({name})-> go 'Activity'  , name
      '/:name?/Members'   : ({name})-> go 'Members'   , name
      '/:name?/Topics'    : ({name})-> go 'Topics'    , name
      '/:name?/Develop'   : ({name})-> go 'StartTab'  , name
      '/:name?/Apps'      : ({name})-> go 'Apps'      , name

      '/:name?/Topics/:topicSlug': @createContentDisplayHandler 'Topics'

      '/:name?/Activity/:activitySlug': @createContentDisplayHandler 'Activity'

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
        status_404 = => @handleNotFound params.name
        KD.remote.cacheable params.name, (err, model, name)->
          switch name?.constructorName
            when 'JAccount'
              appManager.tell 'Members', 'createContentDisplay', model
            when 'JGroup'
              appManager.tell 'Groups', 'createContentDisplay', model
            when 'JTopic'
              appManager.tell 'Topics', 'createContentDisplay', model
            else status_404()

    sharedRoutes = KODING_ROUTES.concat KODING_ROUTES.map (route)->
      route.replace /^\/Groups\/:group/, ''

    for route in sharedRoutes when route not in Object.keys routes
      notFound.call this, route

    routes