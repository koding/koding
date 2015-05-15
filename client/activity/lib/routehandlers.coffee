kd = require 'kd'

module.exports = ActivityRouteHandlers =

  # /Activity/Public
  handlePublicFeed: (info, router) ->

    router.handleRoute "/Activity/Public/Liked",
      replaceState    : yes
      shouldPushState : no


  # /Activity/Public/Liked
  handlePublicFeedMostLiked: ->

    activityPane (pane) -> pane.open 'Most Liked'


  # /Activity/Public/Recent
  handlePublicFeedMostRecent: ->

    activityPane (pane) -> pane.open 'Most Recent'


  # /Activity/Public/Search
  handlePublicFeedSearch: (info) ->

    { params: {name}, query} = info
    activityPane (pane) -> pane.open 'Search', query.q


  # /Activity/Announcement/:slug
  handleAnnouncementFeed: (info) ->

    {params: {name, slug}} = info
    handleChannel 'announcement', slug


  # /Activity/Topic/:slug?
  handleTopicFeed: (info, router) ->

    {params:{name, slug}, query} = info
    if slug is 'public'
    then router.handleRoute '/Activity/Public'
    else handleChannel 'topic', slug


  # /Activity/Post/:slug?
  handleVerbosePost: (info) ->

    {params:{name, slug}, query} = info
    handleChannel 'post', slug


  # /Activity/Message/:slug?
  handlePrivateMessage: (info) ->

    {params:{name, slug}, query} = info
    handleChannel 'message', slug


  # /Activity/:slug
  handlePost: (info) ->

    {params:{name, slug}, query} = info
    handleChannel 'post', slug


  # /Activity/Message/New
  handleNewPrivateMessage: ->

    handleChannel null, null, (app) -> app.getView().showNewMessageForm()


  # /Activity/Topic/All
  handleAllTopics: ->

    handleChannel null, null, (app) -> app.getView().showAllTopicsModal()


  # /Activity/Topic/Following
  handleFollowingTopics: ->

    handleChannel null, null, (app) -> app.getView().showFollowingTopicsModal()


  # /Activity/Chat/All
  handleAllPrivateMessages: ->

    handleChannel null, null, (app) -> app.getView().showAllChatsModal()


  # /Activity
  handleActivityGeneric: (info, router) ->

    {params:{name, slug}, query} = info
    # handle legacy topic routes
    if query.tagged?
    then router.handleRoute "/Activity/Topic/#{query.tagged}"
    else router.handleRoute '/Activity/Public'


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


