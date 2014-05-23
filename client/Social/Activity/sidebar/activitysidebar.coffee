class ActivitySidebar extends KDCustomScrollView

  addEventLogger = (source, eventName) -> source.on eventName, -> log eventName, arguments

  constructor: ->

    super

    {
      activityController
      notificationController
      socialapi
    } = KD.singletons

    activityController.on 'SidebarItemClicked', @bound 'itemClicked'

    addEventLogger notificationController, 'AddedToChannel'
    addEventLogger notificationController, 'RemovedFromChannel'


  viewAppended:->

    super

    @addPublicFeedLink()
    @addHotTopics()
    @addFollowedTopics()
    @addThreads()
    @addMessages()
    # @addChat()


  itemClicked: (item) ->

    # we'll probably do some stuff here later.


  addPublicFeedLink: ->

    {activityController} = KD.singletons

    @wrapper.addSubView publicLink = new CustomLinkView
      title    : 'PUBLIC FEED'
      cssClass : 'kdlistitemview-sidebar-item public-feed-link'
      click    : (event) ->
        KD.utils.stopDOMEvent event
        activityController.emit 'SidebarItemClicked', this
    ,
      name     : 'koding_public_feed'
      id       : "#{KD.getGroup().socialApiChannelId ? 1}"
      channel  : KD.singleton "socialapi"

    publicLink.addSubView @publicFeedCount = new KDCustomHTMLView
      cssClass : 'count'
      tagName  : 'cite'
      partial  : '1'

    publicLink.selectItem = SidebarItem::selectItem.bind publicLink
    activityController.on 'SidebarItemClicked', publicLink.bound 'selectItem'

    # load initial public feed
    KD.utils.defer -> activityController.emit 'SidebarItemClicked', publicLink


  addHotTopics: ->

    @wrapper.addSubView @hotTopics = new ActivitySideView
      title      : 'HOT'
      cssClass   : 'hot topics'
      itemClass  : SidebarTopicItem
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPopularTopics
          limit  : 3
        , callback


  addFollowedTopics: ->

    @wrapper.addSubView @followedTopics = new ActivitySideView
      title    : 'Followed Topics'
      cssClass : 'followed topics'
      itemClass : SidebarTopicItem
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : 5
        , callback


  addThreads: ->

    @wrapper.addSubView @threads = new ActivitySideView
      title    : 'Followed Posts'
      cssClass : 'threads users'
      itemClass : SidebarPinnedItem
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 5
        , callback


  addMessages: ->

    @wrapper.addSubView @messages = new ActivitySideView
      title    : 'Messages'
      cssClass : 'inbox users'
      itemClass : SidebarMessageItem
      dataSource : (callback) ->
        KD.singletons.socialapi.message.fetchPrivateMessages limit : 5, callback


  addChat: ->

    @wrapper.addSubView @chat = new ActivitySideView
      title    : 'Chat'
      cssClass : 'chat users'
      itemClass : SidebarChatMemberItem
      dataSource : (callback) ->
        KD.getGroup().fetchNewestMembers {}, {limit : 10, skip : 0}, callback
