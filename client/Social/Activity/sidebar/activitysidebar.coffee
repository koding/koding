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
      when 'post'  then KD.singletons.socialapi.message.revive message: data  #mapActivity
      when 'topic' then KD.singletons.socialapi.channel.revive data
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
      .on 'AddedToChannel',            @bound 'accountAddedToChannel'
      .on 'RemovedFromChannel',        @bound 'accountRemovedFromChannel'
      .on 'ReplyAdded',                @bound 'replyAdded'
      .on 'MessageAddedToChannel',     @bound 'messageAddedToChannel'
      .on 'MessageRemovedFromChannel', @bound 'messageRemovedFromChannel'

      .on 'MessageListUpdated',        (update) -> log update.event, update
      .on 'ReplyRemoved',              (update) -> log update.event, update

      # .on 'ChannelUpdateHappened',     @bound 'channelUpdateHappened'


  # event handling

  messageAddedToChannel: (update) ->
    if update.channel.typeConstant is 'pinnedactivity'
      @replyAdded update

  messageRemovedFromChannel: (update)->
    log 'messageRemovedFromChannel', update
    {id} = update.channelMessage

    @removeItem id


  replyAdded: (update) ->

    {socialapi}        = KD.singletons
    {unreadCount}      = update
    {id, typeConstant} = update.channelMessage
    type               = 'post'

    # if the reply is added to a private message
    # we need to get the channel instead of the post
    # the other case of reply being added is followed post
    if typeConstant is 'privatemessage'
      type = 'channel'
      id   = update.channel.id

    # so we fetch respectively
    socialapi.cacheable type, id, (err, data) =>

      return KD.showError err  if err

      # and add to the sidebar
      # (if the item is already on sidebar, it's handled on @addItem)
      item = @addItem data, yes
      item.setUnreadCount unreadCount


  messageListUpdated: (update) ->

    {socialapi}        = KD.singletons
    {unreadCount}      = update
    {id, typeConstant} = update.channelMessage
    type               = 'post'


  accountAddedToChannel: (update) ->

    {socialapi} = KD.singletons
    {id}        = update.channel

    socialapi.cacheable 'channel', id, (err, channel) =>

      return KD.showError err  if err

      @addItem channel, yes
      # @updateTopicFollowButtons id, yes  if channel.typeConstant is 'topic'


  accountRemovedFromChannel: (update) ->

    {id, typeConstant} = update.channel

    @removeItem id
    # @updateTopicFollowButtons id, no  if channel.typeConstant is 'topic'


  channelUpdateHappened: (update) ->

    # log 'ChannelUpdateHappened', update

    log 'dont use this, educational purposes only!', update

    # switch update.event
    #   when 'MessageAddedToChannel'     then return @addToChannel update.channelMessage
    #   when 'MessageRemovedFromChannel' then return @removeFromChannel update.channelMessage

    # @setChannelUnreadCount update  if update.channel


  setChannelUnreadCount: ({unreadCount, channel}) ->

    return  unless channel

    {typeConstant, id} = channel

    listController = @getListController typeConstant
    item = listController.itemForId id
    item.setUnreadCount unreadCount  if item?.unreadCount


  getListController: (type) ->

    section = switch type
      when 'topic'                  then @sections.followedTopics
      when 'pinnedactivity', 'post' then @sections.conversations
      when 'privatemessage'         then @sections.messages
      else {}

    return section.listController



  # dom manipulation

  addItem: (data, prepend = no) ->

    listController = @getListController data.typeConstant
    index          = if prepend then listController.getItemCount() else 0

    if item = listController.itemForId data.getId()
      listController.moveItemToIndex item, index
      return item


    return listController.addItem data, index

    # @updateTopicFollowButtons data.getId(), yes


  removeItem: (id) ->

    for name, {listController} of @sections when name isnt 'hot'
      if item = listController.itemForId id
        listController.removeItem item

    # @updateTopicFollowButtons id, no


  updateTopicFollowButtons: (id, state) ->

    return # until we have either fav or hot lists back - SY

    item  = @sections.hot.listController.itemForId id
    state = if state then 'Following' else 'Follow'
    item?.followButton.setState state


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

    @selectedItem = null

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
    # @addHotTopics()
    @addFollowedTopics()
    @addConversations()
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
      noItemText : "You don't follow any topics yet."
      headerLink : new CustomLinkView
        title    : 'ALL'
        href     : KD.utils.groupifyLink '/Activity/Topic/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : 5
        , callback


  addConversations: ->

    @wrapper.addSubView @sections.conversations = new ActivitySideView
      title      : 'Conversations'
      cssClass   : 'threads users'
      itemClass  : SidebarPinnedItem
      dataPath   : 'pinnedMessages'
      delegate   : this
      noItemText : "You didn't participate in any conversations yet."
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
      noItemText : "No private messages yet."
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
