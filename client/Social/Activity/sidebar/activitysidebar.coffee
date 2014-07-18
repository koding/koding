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


  constructor: (options = {}) ->
    options.cssClass  = 'activity-sidebar'

    super options

    {
      notificationController
      socialapi
    } = KD.singletons

    @sections     = {}
    @itemsById    = {}
    @itemsBySlug  = {}
    @itemsByName  = {}
    @selectedItem = null

    notificationController
      .on 'AddedToChannel',            @bound 'accountAddedToChannel'
      .on 'RemovedFromChannel',        @bound 'accountRemovedFromChannel'
      .on 'ReplyAdded',                @bound 'replyAdded'
      .on 'MessageAddedToChannel',     @bound 'messageAddedToChannel'
      .on 'MessageRemovedFromChannel', @bound 'messageRemovedFromChannel'

      .on 'MessageListUpdated',        @bound 'setPostUnreadCount'
      .on 'ReplyRemoved',              (update) -> log update.event, update

      .on 'ParticipantUpdated',        @bound 'handleGlanced'
      # .on 'ChannelUpdateHappened',     @bound 'channelUpdateHappened'


  # event handling

  messageAddedToChannel: (update) ->
    switch update.channel.typeConstant
      when 'pinnedactivity' then @replyAdded update
      when 'topic'          then @handleFollowedFeedUpdate update


  messageRemovedFromChannel: (update) ->
    log 'messageRemovedFromChannel', update
    {id} = update.channelMessage

    @removeItem id


  handleGlanced: (update) -> @selectedItem?.setUnreadCount? update.unreadCount


  handleFollowedFeedUpdate: (update) ->

    {socialapi}   = KD.singletons
    {unreadCount} = update
    {id}          = update.channel

    socialapi.cacheable 'channel', id, (err, data) =>

      return KD.showError err  if err

      item = @addItem data, yes
      item.setUnreadCount unreadCount


  replyAdded: (update) ->

    {socialapi}        = KD.singletons
    {unreadCount}      = update
    {id, typeConstant} = update.channelMessage
    type               = 'post'

    # if the reply is added to a private message
    # we need to get the channel instead of the post
    # the other case of reply being added is followed post
    if typeConstant is 'privatemessage'
      type    = 'channel'
      id      = update.channel.id

    # so we fetch respectively
    socialapi.cacheable type, id, (err, data) =>

      return KD.showError err  if err

      # and add to the sidebar
      # (if the item is already on sidebar, it's handled on @addItem)
      item = @addItem data, yes
      item.setUnreadCount unreadCount


  accountAddedToChannel: (update) ->

    {socialapi}                     = KD.singletons
    {unreadCount, participantCount} = update
    {id, typeConstant}              = update.channel

    socialapi.cacheable typeConstant, id, (err, channel) =>

      return KD.showError err  if err

      item = @addItem channel, yes
      channel.participantCount = participantCount
      channel.emit 'update'
      item.setUnreadCount unreadCount


  accountRemovedFromChannel: (update) ->

    {socialapi}                     = KD.singletons
    {id, typeConstant}              = update.channel
    {unreadCount, participantCount} = update

    # @removeItem id

    socialapi.cacheable typeConstant, id, (err, channel) =>
      channel.participantCount = participantCount
      channel.emit 'update'



  channelUpdateHappened: (update) -> warn 'dont use this, :::educational purposes only!:::', update


  setPostUnreadCount: ({unreadCount, channelMessage}) ->

    return  unless channelMessage

    {typeConstant, id} = channelMessage

    listController = @getListController typeConstant
    item = listController.itemForId id
    item.setUnreadCount unreadCount  if item?.unreadCount


  getItems: ->

    items = [ @public ]
    items = items.concat @sections.followedTopics.listController.getListItems()
    items = items.concat @sections.conversations.listController.getListItems()
    items = items.concat @sections.messages.listController.getListItems()

    return items


  getListController: (type) ->

    section = switch type
      when 'topic'                  then @sections.followedTopics
      when 'pinnedactivity', 'post' then @sections.conversations
      when 'privatemessage'         then @sections.messages
      else {}

    return section.listController


  getItemByData: (data) ->

    item = @itemsById[data.id] or
           @itemsBySlug[data.slug] or
           @itemsByName[data.name]

    return item or null


  # dom manipulation

  addItem: (data, prepend = no) ->

    index          = if prepend then 0
    listController = @getListController data.typeConstant

    if item = @getItemByData data
      listController.moveItemToIndex item, index

      return item

    item = listController.addItem data, index

    return item


  removeItem: (id) ->

    if item = @itemsById[id]

      data           = item.getData()
      listController = @getListController data.typeConstant

      listController.removeItem item


  bindItemEvents: (listView) ->

    listView.on 'ItemWasAdded',   @bound 'registerItem'
    listView.on 'ItemWasRemoved', @bound 'unregisterItem'


  registerItem: (item) ->

    data = item.getData()

    @itemsById[data.id]     = item  if data.id
    @itemsBySlug[data.slug] = item  if data.slug
    @itemsByName[data.name] = item  if data.name


  unregisterItem: (item) ->

    data = item.getData()

    if data.id
      @itemsById[data.id] = null
      delete @itemsById[data.id]

    if data.slug
      @itemsBySlug[data.slug] = null
      delete @itemsBySlug[data.id]

    if data.name
      @itemsByName[data.name] = null
      delete @itemsByName[data.name]


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

    # @wrapper.addSubView new GroupDescription  unless KD.getGroup().slug is 'koding'
    @addGroupDescription()  unless KD.getGroup().slug is 'koding'
    @addPublicFeedLink()
    # @addHotTopics()
    @addFollowedTopics()
    @addConversations()
    @addMessages()
    # @addChat()


  addGroupDescription: ->

    { dock } = KD.singletons

    dock.getView().addSubView new GroupDescription


  addPublicFeedLink: ->

    {activityController} = KD.singletons
    {slug, socialApiChannelId} = KD.getGroup()

    @wrapper.addSubView @public = new CustomLinkView
      title    : 'Public Feed'
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
      noItemText : 'You don\'t follow any topics yet.'
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
      cssClass   : 'conversations'
      itemClass  : SidebarPinnedItem
      dataPath   : 'pinnedMessages'
      delegate   : this
      noItemText : 'You didn\'t participate in any conversations yet.'
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
      cssClass   : 'messages'
      itemClass  : SidebarMessageItem
      dataPath   : 'privateMessages'
      delegate   : this
      noItemText : "No private messages yet."
      headerLink : new CustomLinkView
        cssClass : 'add-icon'
        title    : ' '
        href     : KD.utils.groupifyLink '/Activity/Message/New'
      dataSource : (callback) ->
        KD.singletons.socialapi.message.fetchPrivateMessages
          limit  : 5
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
