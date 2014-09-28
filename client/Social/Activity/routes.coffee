do ->

  appManager = -> KD.singletons.appManager

  activityPane = (callback) ->
    appManager().open 'Activity', (app) ->
      view = app.getView()
      view.open 'topic', 'public'
      callback view.tabs.getPaneByName 'topic-public'

  handleChannel = (type, slug, callback) ->
    callback    ?= (app) -> app.getView().open type, slug
    appManager().open 'Activity', callback

  KD.registerRoutes 'Activity',

    '/:name?/Activity/Public' : ({params: {name}}) ->
      @handleRoute "/#{if name then name else ''}/Activity/Public/Liked",
        replaceState: yes
        shouldPushState: no

    '/:name?/Activity/Public/Liked': ({ params: {name}}) ->
      activityPane (pane) ->
        pane.tabView.showPane pane.tabView.getPaneByName 'Most Liked'

    '/:name?/Activity/Public/Recent': ({ params: {name}}) ->
      activityPane (pane) ->
        pane.tabView.showPane pane.tabView.getPaneByName 'Most Recent'

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
        {router, appManager} = KD.singletons
        router.handleRoute '/Activity/Public'
