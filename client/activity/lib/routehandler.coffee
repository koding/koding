kd = require 'kd'
registerRoutes = require 'app/util/registerRoutes'
lazyrouter = require 'app/lazyrouter'
isBotChannel = require 'activity/util/isbotchannel'

activityPane = (callback) ->
  {appManager} = kd.singletons
  appManager.open 'Activity', (app) ->
    view = app.getView()

    kd.singleton('mainController').ready ->
      view.open 'topic', 'public'
      callback view.tabs.getPaneByName 'topic-public'

handleChannel = (type, slug, callback) ->
  callback    ?= (app) -> app.getView().open type, slug
  {appManager, mainController} = kd.singletons
  mainController.ready -> appManager.open 'Activity', callback

module.exports = -> lazyrouter.bind 'activity', (type, info, state, path, ctx) ->

  switch type
    when 10
      {params: {name}} = info
      ctx.handleRoute "/#{if name then name else ''}/Activity/Public/Liked",
        replaceState: yes
        shouldPushState: no
    when 20
      {params: {name}} = info
      activityPane (pane) -> pane.open 'Most Liked'
    when 30
      {params: {name}} = info
      activityPane (pane) -> pane.open 'Most Recent'
    when 40
      { params: {name}, query} = info
      activityPane (pane) -> pane.open 'Search', query.q
    when 50
      # TODO ~ i tried to unify this route and following 4 routes, couldnt manage
      # to make it work, did not spend so much time on it and gave up, it would be
      # better to have only one route for those 5
      {params: {name, slug}} = info
      handleChannel 'announcement', slug
    when 60
      {params:{name, slug}, query} = info
      if slug is 'public'
      then kd.singletons.router.handleRoute '/Activity/Public'
      else handleChannel 'topic', slug
    when 70
      {params:{name, slug}, query} = info
      handleChannel 'post', slug
    when 80
      {params:{name, slug}, query} = info
      type = if isBotChannel slug then 'bot' else 'message'
      handleChannel type, slug

    when 90
      {params:{name, slug}, query} = info
      handleChannel 'post', slug
    when 100
      handleChannel null, null, (app) -> app.getView().showNewMessageForm()
    when 110
      handleChannel null, null, (app) -> app.getView().showAllTopicsModal()
    when 120
      handleChannel null, null, (app) -> app.getView().showFollowingTopicsModal()
    when 140
      handleChannel null, null, (app) -> app.getView().showAllChatsModal()
    when 150
      {params:{name, slug}, query} = info
      # handle legacy topic routes
      if query.tagged?
        kd.getSingleton('router').handleRoute "/Activity/Topic/#{query.tagged}"
      else
        {router} = kd.singletons
        router.handleRoute '/Activity/Public'
