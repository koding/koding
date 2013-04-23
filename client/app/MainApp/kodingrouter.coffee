class KodingRouter extends KDRouter

  constructor:(@defaultRoute)->

    @openRoutes = {}
    @openRoutesById = {}
    @getSingleton('contentDisplayController')
      .on 'ContentDisplayIsDestroyed', @bound 'cleanupRoute'
    @ready = no
    @getSingleton('mainController').once 'AccountChanged', =>
      @ready = yes
      @utils.defer =>
        @emit 'ready'
    super getRoutes.call this

    @on 'AlreadyHere', ->
      log "You're already here!"
      # new KDNotificationView
      #   title: "You're already here!"
      #   type : 'mini'

    @on 'Params', ({params, query})=>
      #@utils.defer => @getSingleton('groupsController').changeGroup params.name

  listen:->
    super
    unless @userRoute
      @handleRoute @defaultRoute,
        shouldPushState: yes
        replaceState: yes

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
        @handleRoute @getDefaultRoute()

  cleanupRoute:(contentDisplay)->
    delete @openRoutes[@openRoutesById[contentDisplay.id]]

  openSection:(app, group, query)->
    return @once 'ready', @openSection.bind this, arguments...  unless @ready
    @getSingleton('groupsController').changeGroup group, (err)=>
      if err then new KDNotificationView title: err.message
      else
        appManager = KD.getSingleton("appManager")
        appManager.open app
        appManager.tell app, 'handleQuery', query

  handleNotFound:(route)->

    status_404 = =>
      KDRouter::handleNotFound.call this, route

    status_301 = (redirectTarget)=>
      @handleRoute "/#{redirectTarget}", replaceState: yes

    KD.remote.api.JUrlAlias.resolve route, (err, target)->
      if err or not target? then status_404()
      else status_301 target

  getDefaultRoute:-> if KD.isLoggedIn() then '/Activity' else '/Home'

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

  openContent:(name, section, state, route, query)->
    KD.getSingleton("appManager").tell section, 'createContentDisplay', state,
      (contentDisplay)=>
        @openRoutes[route] = contentDisplay
        @openRoutesById[contentDisplay.id] = route
        contentDisplay.emit 'handleQuery', query

  loadContent:(name, section, slug, route, query)->
    routeWithoutParams = route.split('?')[0]
    KD.remote.api.JName.one {name: routeWithoutParams}, (err, name)=>
      if err
        new KDNotificationView title: err?.message or 'An unknown error has occured.'
      else if name?
        models = []
        name.slugs.forEach (slug, i)=>
          {constructorName, usedAsPath} = slug
          selector = {}
          konstructor = KD.remote.api[constructorName]
          selector[usedAsPath] = slug.slug
          konstructor?.one selector, (err, model)=>
            error err if err?
            unless model
              @handleNotFound route
            else
              models[i] = model
              if models.length is name.slugs.length
                @openContent name, section, models, routeWithoutParams, query
      else
        @handleNotFound route

  createContentDisplayHandler:(section)->
    ({params:{name, slug}, query}, state, route)=>
      route = name unless route
      contentDisplay = @openRoutes[route.split('?')[0]]
      if contentDisplay?
        KD.getSingleton("contentDisplayController")
          .hideAllContentDisplays contentDisplay
        contentDisplay.emit 'handleQuery', query
      else if state?
        @openContent name, section, state, route, query
      else
        @loadContent name, section, slug, route, query

  clear:(route="/#{KD.config.groupEntryPoint ? ''}", replaceState=yes)->
    super route, replaceState

  getRoutes =->
    mainController = KD.getSingleton 'mainController'

    clear = @bound 'clear'

    requireLogin =(fn)->
      mainController.accountReady ->
        if KD.isLoggedIn() then __utils.defer fn
        else clear()

    requireLogout =(fn)->
      mainController.accountReady ->
        unless KD.isLoggedIn() then __utils.defer fn
        else clear()

    createSectionHandler = (sec)->
      ({params:{name}, query})-> @openSection sec, name, query

    createContentHandler = @bound 'createContentDisplayHandler'

    routes =

      '/' : handleRoot
      ''  : handleRoot

      # verbs
      '/:name?/Login'     : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'login'
      '/:name?/Logout'    : ({params:{name}})->
        requireLogin  -> mainController.doLogout()
      '/:name?/Register'  : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'register'
      '/:name?/Join'      : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'join'
      '/:name?/Recover'   : ({params:{name}})->
        requireLogout -> mainController.loginScreen.animateToForm 'recover'

      # section
      # TODO: nested groups are disabled.
      '/:name?/Home'                    : createSectionHandler 'Home'
      '/:name?/Groups'                  : createSectionHandler 'Groups'
      '/:name?/Activity'                : createSectionHandler 'Activity'
      '/:name?/Members'                 : createSectionHandler 'Members'
      '/:name?/Topics'                  : createSectionHandler 'Topics'
      '/:name?/Develop'                 : createSectionHandler 'StartTab'
      '/:name?/Apps'                    : createSectionHandler 'Apps'
      '/:name?/Account'                 : createSectionHandler 'Account'

      # group dashboard
      '/:name?/Dashboard'               : (routeInfo, state, route)->
        {name} = routeInfo.params
        n = name ? 'koding'
        KD.remote.cacheable n, (err, [group], nameObj)=>
          @openContent name, 'Groups', group, route

      # content
      '/:name?/Topics/:slug'            : createContentHandler 'Topics'
      '/:name?/Activity/:slug'          : createContentHandler 'Activity'
      '/:name?/Apps/:slug'              : createContentHandler 'Apps'

      '/:name?/Recover/:recoveryToken': ({params:{recoveryToken}})->
        return  if recoveryToken is 'Password'
        mainController.appReady =>
          # TODO: DRY this one
          $('body').addClass 'login'
          mainController.loginScreen.show()
          mainController.loginScreen.$().css marginTop : 0
          mainController.loginScreen.hidden = no

          recoveryToken = decodeURIComponent recoveryToken
          {JPasswordRecovery} = KD.remote.api
          JPasswordRecovery.validate recoveryToken, (err, isValid)=>
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
            loginScreen.handleInvitation invite
          @clear()

      '/:name?/Verify/:confirmationToken': ({params:{confirmationToken}})->
        confirmationToken = decodeURIComponent confirmationToken
        KD.remote.api.JEmailConfirmation.confirmByToken confirmationToken, (err)=>
          location.replace '#'
          if err
            error err
            new KDNotificationView
              title: "Something went wrong, please try again later!"
          else
            new KDNotificationView
              title: "Thanks for confirming your email address!"
          @clear()

      '/member/:username': ({params:{username}})->
        @handleRoute "/#{username}", replaceState: yes

      '/:name?/Unsubscribe/:unsubscribeToken/:opt?':
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
          router = KD.getSingleton 'router'
          switch model?.bongo_?.constructorName
            when 'JAccount'
              createContentHandler 'Members'
            when 'JGroup'
              {params:{name}, query} = routeInfo
              router.handleRoute "/#{name}/Activity"
            else status_404()

        nameHandler =(routeInfo, state, route)->

          {params} = routeInfo
          status_404 = @handleNotFound.bind this, params.name

          if state?
            open routeInfo, state, status_404

          else
            KD.remote.cacheable params.name, (err, [model], name)->
              open routeInfo, model, status_404

    routes