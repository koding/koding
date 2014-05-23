class ActivitySidebar extends KDCustomScrollView

  addEventLogger = (source, eventName) -> source.on eventName, -> log eventName, arguments

  constructor: ->

    super

    {
      notificationController
      socialapi
    } = KD.singletons

    addEventLogger notificationController, 'AddedToChannel'
    addEventLogger notificationController, 'RemovedFromChannel'

    appView       = @getDelegate()
    @sections     = {}
    @selectedItem = null



    # fixme:
    # this item selection is a bit tricky
    # depends on multiple parts:
    # - sidebaritem's lastTimestamp
    # - the item which is being clicked
    # - and what the route suggests
    # needs to be simplified
    appView.on 'PaneRequested', (type, id) =>

      @deselectAllItems()

      if type is 'public'
      then return @public.setClass 'selected'
      else @public.unsetClass 'selected'

      candidateItems = []
      for own name, {listController} of @sections

        for item in listController.itemsOrdered
          data = item.getData()
          if data.typeConstant is type and "#{data.id}" is "#{id}"
            candidateItems.push item

      candidateItems.sort (a, b) -> a.lastClickedTimestamp < b.lastClickedTimestamp

      if candidateItems.first
        listController.selectSingleItem candidateItems.first
        @selectedItem = candidateItems.first


  deselectAllItems: ->

    for own name, {listController} of @sections

      listController.deselectAllItems()


  getItemById: (id) ->

    item = null
    for own name, section of @sections

      item = section.listController.itemsIndexed[id]
      break  if item

    return item


  viewAppended: ->

    super

    @addPublicFeedLink()
    @addHotTopics()
    @addFollowedTopics()
    @addFollowedPosts()
    @addMessages()
    # @addChat()


  addPublicFeedLink: ->

    {activityController} = KD.singletons

    @wrapper.addSubView @public = new CustomLinkView
      title    : 'PUBLIC FEED'
      href     : '/Activity/Public'
      cssClass : 'kdlistitemview-sidebar-item public-feed-link'
    ,
      name     : 'koding_public_feed'
      id       : "#{KD.getGroup().socialApiChannelId ? 1}"
      channel  : KD.singleton "socialapi"


    @public.addSubView new KDCustomHTMLView
      cssClass : 'count'
      tagName  : 'cite'
      partial  : '1'

    # # load initial public feed
    # KD.utils.defer -> activityController.emit 'SidebarItemClicked', @public


  addHotTopics: ->

    @wrapper.addSubView @sections['hot'] = new ActivitySideView
      title      : 'HOT'
      cssClass   : 'hot topics'
      itemClass  : SidebarTopicItem
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPopularTopics
          limit  : 3
        , callback


  addFollowedTopics: ->

    @wrapper.addSubView @sections['followedTopics'] = new ActivitySideView
      title    : 'Followed Topics'
      cssClass : 'followed topics'
      itemClass : SidebarTopicItem
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : 5
        , callback


  addFollowedPosts: ->

    @wrapper.addSubView @sections['followedPosts'] = new ActivitySideView
      title    : 'Followed Posts'
      cssClass : 'threads users'
      itemClass : SidebarPinnedItem
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 5
        , callback


  addMessages: ->

    @wrapper.addSubView @sections['messages'] = new ActivitySideView
      title      : 'Messages'
      cssClass   : 'inbox users'
      itemClass  : SidebarMessageItem
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.message.fetchPrivateMessages
          limit : 3
          skip  : 0
        , callback


  addChat: ->

    @wrapper.addSubView @sections['chat'] = new ActivitySideView
      title    : 'Chat'
      cssClass : 'chat users'
      itemClass : SidebarChatMemberItem
      delegate   : this
      dataSource : (callback) ->
        KD.getGroup().fetchNewestMembers {}, {limit : 10, skip : 0}, callback
