class ActivitySidebar extends KDCustomScrollView


  typeMap =
    privatemessage : 'Message'
    topic          : 'Topic'
    post           : 'Post'
    chat           : 'Chat'


  slugProps =
    SocialMessage : 'slug'
    SocialChannel : 'name'


  revive = (data) ->

    return switch data.typeConstant
      when 'post' then (KD.singleton 'socialapi').message.revive message: data
      when 'topic' then (KD.singleton 'socialapi').mapChannel data
      else data


  constructor: ->

    super

    {
      notificationController
      socialapi
    } = KD.singletons

    @sections     = {}
    @selectedItem = null

    notificationController
      .on 'AddedToChannel',            @bound 'addToChannel'
      .on 'RemovedFromChannel',        @bound 'removeFromChannel'
      .on 'ChannelUpdateHappened',     @bound 'notificationHasArrived'
      .on 'NotificationHasArrived',    @bound 'notificationHasArrived'


  addToChannel: (channel) ->

    data           = revive channel
    listController = @getListController data.typeConstant

    return  if listController.itemForId data.id

    listController.addItem data
    @updateTopicFollowButtons data


  removeFromChannel: (channel) ->

    channel        = revive channel
    listController = @getListController channel.typeConstant
    item           = listController.itemForId channel.getId()
    listController.removeItem item
    @updateTopicFollowButtons channel


  notificationHasArrived: (update) ->

    log 'notificationHasArrived', update

    switch update.event
      when 'MessageAddedToChannel'     then return @addToChannel update.channelMessage
      when 'MessageRemovedFromChannel' then return @removeFromChannel update.channelMessage

    {unreadCount, channel} = update
    {typeConstant, id}     = channel

    listController = @getListController typeConstant
    item = listController.itemForId id
    item.setUnreadCount unreadCount  if item?.unreadCount


  getListController: (type) ->

    section = switch type
      when 'topic'                  then @sections.followedTopics
      when 'pinnedactivity', 'post' then @sections.followedPosts
      when 'privatemessage'         then @sections.messages
      else {}

    return section.listController


  updateTopicFollowButtons: (channel) ->

    for name in ['hot', 'followedTopics']
      item = @sections[name].listController.itemForId channel.getId()
      continue  unless item
      state = if channel.isParticipant then 'Following' else 'Follow'
      item.followButton.setState state


  # fixme:
  # this item selection is a bit tricky
  # depends on multiple parts:
  # - sidebaritem's lastTimestamp
  # - the item which is being clicked
  # - and what the route suggests
  # needs to be simplified
  selectItemByRouteOptions: (type, slug_) ->

    @deselectAllItems()

    if type is 'public'
      @selectedItem = @public
      @public.setClass 'selected'
      return

    else
      @public.unsetClass 'selected'

    type       = 'privatemessage'  if type is 'message'
    candidates = []

    for own name_, {listController} of @sections

      for item in listController.getListItems()

        data = item.getData()
        {typeConstant, id, name , slug} = data

        if typeConstant is type and slug_ in [id, name, slug]
          candidates.push item

    candidates.sort (a, b) -> a.lastClickedTimestamp < b.lastClickedTimestamp

    if candidates.first
      listController.selectSingleItem candidates.first
      @selectedItem = candidates.first


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

      section.listController.getListItems().forEach (item)->
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
      title      : 'TRENDING'
      cssClass   : 'hot topics hidden'
      itemClass  : SidebarTopicItem
      dataPath   : 'popularTopics'
      delegate   : this
      headerLink : new CustomLinkView
        title    : 'ALL'
        href     : KD.utils.groupifyLink '/Activity/Topic/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPopularTopics
          limit  : 5
        , callback


  addFollowedTopics: ->

    @wrapper.addSubView @sections.followedTopics = new ActivitySideView
      title      : 'My Feeds'
      cssClass   : 'followed topics'
      itemClass  : SidebarTopicItem
      dataPath   : 'followedChannels'
      delegate   : this
      headerLink : new CustomLinkView
        title    : 'ALL'
        href     : KD.utils.groupifyLink '/Activity/Topic/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : 5
        , callback


  addFollowedPosts: ->

    @wrapper.addSubView @sections.followedPosts = new ActivitySideView
      title      : 'Conversations'
      cssClass   : 'threads users'
      itemClass  : SidebarPinnedItem
      dataPath   : 'pinnedMessages'
      delegate   : this
      headerLink : new CustomLinkView
        title    : 'ALL'
        href     : KD.utils.groupifyLink '/Activity/Post/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 5
        , callback


  addMessages: ->

    @wrapper.addSubView @sections.messages = new ActivitySideView
      title      : 'Private Conversations'
      cssClass   : 'inbox users'
      itemClass  : SidebarMessageItem
      dataPath   : 'privateMessages'
      delegate   : this
      headerLink : new CustomLinkView
        title    : 'NEW'
        href     : KD.utils.groupifyLink '/Activity/Message/New'
      dataSource : (callback) ->
        KD.singletons.socialapi.message.fetchPrivateMessages
          limit : 5
        , callback


  addChat: ->

    @wrapper.addSubView @sections.chat = new ActivitySideView
      title      : 'Chat'
      cssClass   : 'chat users'
      itemClass  : SidebarChatMemberItem
      delegate   : this
      headerLink : new CustomLinkView
        title    : 'NEW'
        href     : KD.utils.groupifyLink '/Activity/Chat/New'
      dataSource : (callback) ->
        KD.getGroup().fetchNewestMembers {}, {limit : 10}, callback
