do ->

  currentTab = 'Liked'

  activityPane = (callback) ->
    {appManager} = KD.singletons
    appManager.open 'Activity', (app) ->
      view = app.getView()
      view.open 'topic', 'public'
      callback view.tabs.getPaneByName 'topic-public'

  handleChannel = (type, slug, callback) ->
    callback    ?= (app) -> app.getView().open type, slug
    {appManager} = KD.singletons
    appManager.open 'Activity', callback

  KD.registerRoutes 'Activity',

    '/:name?/Activity/Public' : ({params: {name}}) ->
      @handleRoute "/#{if name then name else ''}/Activity/Public/#{currentTab}",
        replaceState: yes
        shouldPushState: no

    '/:name?/Activity/Public/Liked': ({ params: {name}}) ->
      currentTab = 'Liked'
      activityPane (pane) -> pane.open 'Most Liked'

    '/:name?/Activity/Public/Recent': ({ params: {name}}) ->
      currentTab = 'Recent'
      activityPane (pane) -> pane.open 'Most Recent'

    '/:name?/Activity/Public/Search': ({ params: {name}, query}) ->
      activityPane (pane) -> pane.open 'Search', query.q


    # TODO ~ i tried to unify this route and following 4 routes, couldnt manage
    # to make it work, did not spend so much time on it and gave up, it would be
    # better to have only one route for those 5
    '/:name?/Activity/Announcement/:slug' : ({params: {name, slug}}) ->
      handleChannel 'announcement', slug

    '/:name?/Activity/Topic/:slug?' : ({params:{name, slug}, query}) ->
      if slug is 'public'
      then KD.singletons.router.handleRoute '/Activity/Public'
      else handleChannel 'topic', slug

    '/:name?/Activity/Post/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'post', slug

    '/:name?/Activity/Message/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'message', slug

    '/:name?/Activity/:slug' : ({params:{name, slug}, query}) ->
      handleChannel 'post', slug

    '/:name?/Activity/Message/New' : ->
      handleChannel null, null, (app) -> app.getView().showNewMessageForm()

    '/:name?/Activity/Topic/All' : ({params:{name, slug}, query}) ->
      handleChannel null, null, (app) -> app.getView().showAllTopicsModal()

    '/:name?/Activity/Topic/Following' : ({params:{name, slug}, query}) ->
      handleChannel null, null, (app) -> app.getView().showFollowingTopicsModal()

    '/:name?/Activity/Post/All' : ({params:{name, slug}, query}) ->
      handleChannel null, null, (app) -> app.getView().showAllConversationsModal()

    '/:name?/Activity/Chat/All' : ->
      handleChannel null, null, (app) -> app.getView().showAllChatsModal()

    '/:name?/Activity' : ({params:{name, slug}, query}) ->
      # handle legacy topic routes
      if query.tagged?
        KD.getSingleton('router').handleRoute "/Activity/Topic/#{query.tagged}"
      else
        {router} = KD.singletons
        router.handleRoute '/Activity/Public'
