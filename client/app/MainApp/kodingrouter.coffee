class KodingRouter extends KDRouter
  constructor:(@defaultRoute)->
    @openRoutes = {}
    @openRoutesById = {}
    KD.getSingleton('contentDisplayController')
      .on 'ContentDisplayIsDestroyed', @cleanupRoute.bind @
    super getRoutes.call this

    @on 'AlreadyHere', ->
      new KDNotificationView title: "You're already here!"

    @handleRoute defaultRoute

  nicenames = {
    JTag      : 'Topics'
    JApp      : 'Apps'
    StartTab  : 'Develop'
  }

  getSectionName =(model)->
    sectionName = nicenames[model.bongo_.constructorName]
    if sectionName? then " - #{sectionName}" else ''

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

  cleanupRoute:(contentDisplay)->
    delete @openRoutes[@openRoutesById[contentDisplay.id]]
  
  go:(app, group, query, rest...)->
    pageTitle = nicenames[app] ? app
    @setPageTitle pageTitle
    unless group?
      appManager.openApplication app
    else
      appManager.tell app, 'setGroup', group
    if Object.keys(query).length
      appManager.tell app, 'handleQuery', query

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

  setPageTitle:(title="Koding")->
    document.title = title

  getContentTitle:(model)->
    {JAccount, JStatusUpdate, JGroup} = KD.remote.api
    @utils.shortenText (switch model.constructor
      when JAccount then "#{model.profile.firstName} #{model.profile.lastName}"
      when JStatusUpdate then model.body
      when JGroup then model.title
      else "#{model.title}#{getSectionName model}"
    ), 100

  openContent:(name, section, state, route)->
    @setPageTitle @getContentTitle state
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
    ({name, topicSlug}, state, route)=>
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
    # Abbreviations used below:
    # "acc" is short for "accumulator"
    # "kv" is short for "key-value pair"
    # "sec" is short for "section"
    mainController = KD.getSingleton 'mainController'

    kv =(acc, sec)-> acc[sec[0]] = sec[1]; acc

    goToContent = 'Activity Apps Groups Members Topics'
      .split(' ')
      .map((sec)=> [sec, @createContentDisplayHandler sec])
      .reduce kv, {}

    goToSection = 'Account Activity Apps Groups Members StartTab Topics'
      .split(' ')
      .map((sec)-> [sec, ({params:{name}, query})-> @go sec, name, query])
      .reduce kv, {}

    routes =

      '/' : handleRoot
      ''  : handleRoot

      # verbs
      '/:name?/Login'     : ({params:{name}})-> mainController.doLogin name
      '/:name?/Logout'    : ({params:{name}})-> mainController.doLogout name; @clear()
      '/:name?/Register'  : ({params:{name}})-> mainController.doRegister name
      '/:name?/Join'      : ({params:{name}})-> mainController.doJoin name
      '/:name?/Recover'   : ({params:{name}})-> mainController.doRecover name

      # nouns
      '/:name?/Groups'                  : goToSection.Groups
      '/:name?/Activity'                : goToSection.Activity
      '/:name?/Members'                 : goToSection.Members
      '/:name?/Topics'                  : goToSection.Topics
      '/:name?/Develop'                 : goToSection.StartTab
      '/:name?/Apps'                    : goToSection.Apps
      '/:name?/Account'                 : goToSection.Account

      # content displays:
      '/:name?/Topics/:topicSlug'       : goToContent.Topics
      '/:name?/Activity/:activitySlug'  : goToContent.Activity
      '/:name?/Apps/:appSlug'           : goToContent.Apps

      '/recover/:recoveryToken': ({params:{recoveryToken}})->
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

      '/invitation/:inviteToken': ({params:{inviteToken}})->
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

      '/verify/:confirmationToken': ({params:{confirmationToken}})->
        confirmationToken = decodeURIComponent confirmationToken
        KD.remote.api.JEmailConfirmation.confirmByToken confirmationToken, (err)->
          location.replace '#'
          if err
            throw err
            new KDNotificationView
              title: "Something went wrong, please try again later!"
          else
            new KDNotificationView
              title: "Thanks for confirming your email address!"

      '/member/:username': ({params:{username}})->
        @handleRoute "/#{username}", replaceState: yes

      # top level names:
      '/:name':do->
        open =(routeInfo, model, status_404)->
          switch model?.bongo_?.constructorName
            when 'JAccount' then goToContent.Members routeInfo, model
            when 'JGroup'   then goToContent.Groups  routeInfo, model
            when 'JTopic'   then goToContent.Topics  routeInfo, model
            else status_404()
        nameHandler =(routeInfo, state, route)->
          {params} = routeInfo
          status_404 = @handleNotFound.bind this, params.name
          if state?
            open routeInfo, state, status_404
          else
            KD.remote.cacheable params.name, (err, model, name)->
              open routeInfo, model, status_404

    sharedRoutes = KODING_ROUTES.concat KODING_ROUTES.map (route)->
      route.replace /^\/Groups\/:group/, ''

    for route in sharedRoutes when route not in Object.keys routes
      notFound.call this, route

    routes