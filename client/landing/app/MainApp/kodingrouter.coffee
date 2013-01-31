class KodingRouter extends KDRouter

  constructor:(@defaultRoute)->
    @openRoutes = {}
    @openRoutesById = {}
    @getSingleton('contentDisplayController')
      .on 'ContentDisplayIsDestroyed', @bound 'cleanupRoute'
    super getRoutes.call this

    @on 'AlreadyHere', ->
      new KDNotificationView title: "You're already here!"

    unless @userRoute
      @handleRoute defaultRoute,
        shouldPushState: yes
        replaceState: yes

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
    # don't load the root content when we're just consuming a hash fragment
    unless location.hash.length
      KD.getSingleton("contentDisplayController").hideAllContentDisplays()

      if KD.isLoggedIn()
        @handleRoute @userRoute or @getDefaultRoute(), replaceState: yes
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
      @emit 'GroupChanged', group
      appManager.tell app, 'setGroup', group
    appManager.tell app, 'handleQuery', query

  stripTemplate =(str, konstructor)->
    {slugTemplate} = konstructor
    slugStripPattern = /^(.+)?(#\{slug\})(.+)?$/
    re = RegExp slugTemplate.replace slugStripPattern,
      (tmp, begin, slug, end)-> "^#{begin ? ''}(.*)#{end ? ''}$"
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

  setPageTitle:(title="Koding")-> document.title = Encoder.htmlDecode title

  getContentTitle:(model)->
    {JAccount, JStatusUpdate, JGroup} = KD.remote.api
    @utils.shortenText(
      switch model.constructor
        when JAccount       then "#{model.profile.firstName} #{model.profile.lastName}"
        when JStatusUpdate  then  model.body
        when JGroup         then  model.title
        else                      "#{model.title}#{getSectionName model}"
    , maxLength: 100) # max char length of the title

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
          error err  if err?
          @openContent name, section, model, route
      else
        @handleNotFound route

  createContentDisplayHandler:(section)->
    ({params:{name, slug}}, state, route)=>
      contentDisplay = @openRoutes[route]
      if contentDisplay?
        KD.getSingleton("contentDisplayController")
          .hideAllContentDisplays contentDisplay
      else
        # appManager.tell section, 'setGroup', name  if name?
        if state?
          @openContent name, section, state, route
        else
          @loadContent name, section, slug, route

  createLinks =(names, fn)->
    names = names.split ' '  if names.split?
    names
      .map (name)->
        [name, fn name]
      .reduce (acc, [name, link])->
        acc[name] = link
        acc
      , {}

  getRoutes =->
    mainController = KD.getSingleton 'mainController'

    content = createLinks(
      # 'Activity Apps Groups Members Topics'
      'Activity Apps Members Topics'
      (sec)=> @createContentDisplayHandler sec
    )

    section = createLinks(
      # 'Account Activity Apps Groups Members StartTab Topics'
      'Account Activity Apps Inbox Members StartTab Topics'
      (sec)-> ({params:{name}, query})-> @go sec, name, query
    )

    clear = @bound 'clear'

    requireLogin =(fn)->
      mainController.accountReady ->
        # console.log 'faafafaf'
        if KD.isLoggedIn() then fn()
        else clear()

    requireLogout =(fn)->
      mainController.accountReady ->
        # console.log 'sfsfsfsfsfsf', KD.whoami(), KD.isLoggedIn()
        unless KD.isLoggedIn() then fn()
        else clear()

    routes =

      '/' : handleRoot
      ''  : handleRoot

      # verbs
      '/:name?/Login'     : ({params:{name}})->
        requireLogout -> mainController.doLogin name
      '/:name?/Logout'    : ({params:{name}})->
        requireLogin  -> mainController.doLogout name; clear()
      '/:name?/Register'  : ({params:{name}})->
        requireLogout -> mainController.doRegister name
      '/:name?/Join'      : ({params:{name}})->
        requireLogout -> mainController.doJoin name
      '/:name?/Recover'   : ({params:{name}})->
        requireLogout -> mainController.doRecover name

      # section
      # '/:name?/Groups'                  : section.Groups
      '/:name?/Activity'                : section.Activity
      '/:name?/Members'                 : section.Members
      '/:name?/Topics'                  : section.Topics
      '/:name?/Develop'                 : section.StartTab
      '/:name?/Apps'                    : section.Apps
      '/:name?/Account'                 : section.Account

      # content
      '/:name?/Topics/:topicSlug'       : content.Topics
      '/:name?/Activity/:activitySlug'  : content.Activity
      '/:name?/Apps/:appSlug'           : content.Apps

      '/:name?/Recover/:recoveryToken': ({params:{recoveryToken}})->
        return  if recoveryToken is 'Password'
        mainController.appReady =>
          # TODO: DRY this one
          $('body').addClass 'login'
          mainController.loginScreen.show()
          mainController.loginScreen.$().css marginTop : 0
          mainController.loginScreen.hidden = no

          recoveryToken = decodeURIComponent recoveryToken
          KD.remote.api.JPasswordRecovery.validate recoveryToken, (err, isValid)=>
            if err or !isValid
              new KDNotificationView
                title   : 'Something went wrong.'
                content : err?.message or """
                  That doesn't seem to be a valid recovery token!
                  """
            else
              {loginScreen} = mainController
              loginScreen.headBannerShowRecovery recoveryToken
            @clear()

      '/:name?/Invitation/:inviteToken': ({params:{inviteToken}})->
        inviteToken = decodeURIComponent inviteToken
        if KD.isLoggedIn()
          new KDNotificationView
            title: 'Could not redeem invitation because you are already logged in.'
        else KD.remote.api.JInvitation.byCode inviteToken, (err, invite)=>
          if err or !invite? or invite.status not in ['active','sent']
            if err then error err
            new KDNotificationView
              title: 'Invalid invitation code!'
          else
            {loginScreen} = mainController
            loginScreen.headBannerShowInvitation invite
          @clear()

      '/:name?/Verify/:confirmationToken': ({params:{confirmationToken}})->
        confirmationToken = decodeURIComponent confirmationToken
        KD.remote.api.JEmailConfirmation.confirmByToken confirmationToken, (err)=>
          location.replace '#'
          if err
            throw err
            new KDNotificationView
              title: "Something went wrong, please try again later!"
          else
            new KDNotificationView
              title: "Thanks for confirming your email address!"
          @clear()

      '/member/:username': ({params:{username}})->
        @handleRoute "/#{username}", replaceState: yes

      '/:name?/Unsubscribe/:unsubscribeToken/:opt?': \
      ({params:{unsubscribeToken, opt}})->
        opt              = decodeURIComponent opt
        unsubscribeToken = decodeURIComponent unsubscribeToken
        KD.remote.api.JMailNotification.unsubscribeWithId \
        unsubscribeToken, opt, (err, content)=>
          if err or not content
            title   = 'An error occured'
            content = 'Invalid unsubscribe token provided.'
            log err
          else
            title   = 'E-mail settings updated'

          modal = new KDModalView
            title        : title
            overlay      : yes
            cssClass     : "new-kdmodal"
            content      : "<div class='modalformline'>#{content}</div>"
            buttons      :
              "Close"    :
                style    : "modal-clean-gray"
                callback : (event)->
                  modal.destroy()
          @clear()

      # top level names
      '/:name':do->

        open =(routeInfo, model, status_404)->
          switch model?.bongo_?.constructorName
            when 'JAccount' then content.Members routeInfo, model
            # when 'JGroup'   then content.Groups  routeInfo, model
            when 'JTopic'   then content.Topics  routeInfo, model
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