do ->

  createContentDisplayHandler = (section, passOptions = no) ->

    ({params:{name, slug}, query}, models, route)->

      {router} = KD.singletons
      route = name unless route
      contentDisplay = router.openRoutes[route.split('?')[0]]

      if contentDisplay?
        KD.singleton('display').hideAllDisplays contentDisplay
        contentDisplay.emit 'handleQuery', query
      else if models?
        router.openContent name, section, models, route, query, passOptions
      else
        router.loadContent name, section, slug, route, query, passOptions


  handleChannel = (type, slug) ->
    {appManager} = KD.singletons
    appManager.open 'Activity', (app) -> app.getView().open type, slug


  handleNewMessage = (type, slug) ->
    {appManager} = KD.singletons
    appManager.open 'Activity', (app) -> app.getView().showNewMessageModal()


  KD.registerRoutes 'Activity',

    '/:name?/Activity/Public' : ({params: {name}}) -> handleChannel 'public', name or 'koding'

    '/:name?/Activity/Topic/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'topic', slug

    '/:name?/Activity/Post/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'post', slug

    '/:name?/Activity/Message/New' : handleNewMessage

    '/:name?/Activity/Message/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'message', slug

    '/:name?/Activity/Chat/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'chat', slug

    '/:name?/Activity/:slug?' : ({params:{name, slug}, query}) ->
      {router, appManager} = KD.singletons
      unless slug
      then router.openSection 'Activity', name, query
      else createContentDisplayHandler('Activity') arguments...

    '/:name?/Activity' : ({params:{name, slug}, query}) ->
      {router, appManager} = KD.singletons
      router.handleRoute '/Activity/Public'
