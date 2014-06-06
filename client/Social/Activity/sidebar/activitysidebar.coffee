class ActivitySidebar extends KDCustomScrollView


  typeMap =
    privatemessage : 'Message'
    topic          : 'Topic'
    post           : 'Post'
    chat           : 'Chat'


  slugProps =
    SocialMessage : 'slug'
    SocialChannel : 'name'


  revive = (obj) -> KD.singletons.socialapi.mapChannels(obj).first


  constructor: ->

    super

    {
      notificationController
      socialapi
    } = KD.singletons

    @sections     = {}
    @selectedItem = null

    notificationController.on 'AddedToChannel', (channel) =>

      revived        = revive channel
      listController = @getListController revived.typeConstant

      listController.addItem revived


    notificationController.on 'RemovedFromChannel', (channel) =>

      revived        = revive channel
      listController = @getListController revived.typeConstant
      item           = listController.itemsIndexed[revived.id]
      listController.removeItem item


    notificationController
      .on 'ChannelUpdateHappened',  @bound 'notificationHasArrived'
      .on 'NotificationHasArrived', @bound 'notificationHasArrived'


  notificationHasArrived: (update) ->

    {unreadCount, channel} = update
    {typeConstant, id}     = channel

    listController = @getListController typeConstant

    item = listController.itemForId id

    item.setUnreadCount unreadCount  if item?.unreadCount


  getListController: (type) ->

    section = switch type
      when 'topic'          then @sections.followedTopics
      when 'privatemessage' then @sections.messages
      else {}

    return section.listController


  # fixme:
  # this item selection is a bit tricky
  # depends on multiple parts:
  # - sidebaritem's lastTimestamp
  # - the item which is being clicked
  # - and what the route suggests
  # needs to be simplified
  selectItemByRouteOptions: (type, slug) ->

    @deselectAllItems()

    if type is 'public'
      @selectedItem = @public
      return @public.setClass 'selected'
    else
      @public.unsetClass 'selected'

    type = 'privatemessage' if type is 'message'

    candidateItems = []
    for own name, {listController} of @sections

      for item in listController.itemsOrdered
        data = item.getData()
        if data.typeConstant is type and (data.id is slug or data.name is slug or data.slug is slug)
          candidateItems.push item

    candidateItems.sort (a, b) -> a.lastClickedTimestamp < b.lastClickedTimestamp

    if candidateItems.first
      listController.selectSingleItem candidateItems.first
      @selectedItem = candidateItems.first


  deselectAllItems: ->

    for own name, {listController} of @sections

      listController.deselectAllItems()


  # getItemById: (id) ->

  #   item = null
  #   for own name, section of @sections

  #     item = section.listController.itemsIndexed[id]
  #     break  if item

  #   return item


  getItemByRouteParams: (type, slug) ->

    typeConstant = k for own k, v of typeMap when v = type

    itemWeWant = null
    for own name, section of @sections

      section.listController.itemsOrdered.forEach (item)->
        if item.typeConstant is typeConstant
          slugProp = slugProps[item.bongo_.constructorName]
          itemWeWant = item[slugProp] is slug

    return itemWeWant


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
    {slug, socialApiChannelId} = KD.getGroup()

    @wrapper.addSubView @public = new CustomLinkView
      title    : 'PUBLIC FEED'
      href     : '/Activity/Public'
      cssClass : 'kdlistitemview-sidebar-item public-feed-link'
    ,
      name         : slug
      typeConstant : 'group'
      groupName    : slug
      id           : socialApiChannelId ? '1'

    @public.addSubView new KDCustomHTMLView
      cssClass : 'count hidden'
      tagName  : 'cite'
      partial  : '1'


  addHotTopics: ->

    @wrapper.addSubView @sections.hot = new ActivitySideView
      title      : 'HOT'
      cssClass   : 'hot topics'
      itemClass  : SidebarTopicItem
      dataPath   : 'popularTopics'
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPopularTopics
          limit  : 3
        , callback


  addFollowedTopics: ->

    @wrapper.addSubView @sections.followedTopics = new ActivitySideView
      title      : 'Followed Topics'
      cssClass   : 'followed topics'
      itemClass  : SidebarTopicItem
      dataPath   : 'followedChannels'
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : 5
        , callback


  addFollowedPosts: ->

    @wrapper.addSubView @sections.followedPosts = new ActivitySideView
      title      : 'Followed Posts'
      cssClass   : 'threads users'
      itemClass  : SidebarPinnedItem
      dataPath   : 'pinnedMessages'
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 5
        , callback


  addMessages: ->

    @wrapper.addSubView @sections.messages = new ActivitySideView
      title      : 'Messages'
      cssClass   : 'inbox users'
      itemClass  : SidebarMessageItem
      dataPath   : 'privateMessages'
      delegate   : this
      dataSource : (callback) ->
        KD.singletons.socialapi.message.fetchPrivateMessages
          limit : 3
          skip  : 0
        , callback


  addChat: ->

    @wrapper.addSubView @sections.chat = new ActivitySideView
      title    : 'Chat'
      cssClass : 'chat users'
      itemClass : SidebarChatMemberItem
      delegate   : this
      dataSource : (callback) ->
        KD.getGroup().fetchNewestMembers {}, {limit : 10, skip : 0}, callback
