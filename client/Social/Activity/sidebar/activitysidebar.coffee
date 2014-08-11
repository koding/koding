class ActivitySidebar extends KDCustomHTMLView


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

    options.cssClass  = 'app-sidebar'

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
      else  @handleFollowedFeedUpdate update


  messageRemovedFromChannel: (update) ->

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

      # when someone replies to a user's post, we locally mark that post, and
      # any cached copies as "followed" by that user.
      socialapi.eachCached data.getId(), (it) -> it.isFollowed = yes
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


  setPostUnreadCount: (data) ->
    {unreadCount, channelMessage} = data
    return  unless channelMessage

    {typeConstant, id} = channelMessage

    listController = @getListController typeConstant
    item = listController.itemForId id

    # if we are getting updates about a message it means we are following it
    item.isFollowed = yes if item

    # if we are getting updates about a message that is not in the channel it
    # should be added into list
    @replyAdded data  unless item

    item.setUnreadCount unreadCount  if item?.unreadCount


  getItems: ->

    items = []
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

    typeConstant = k for own k, v of typeMap when v is type

    itemWeWant = null
    for own name, section of @sections

      section.listController.getListItems().forEach (item)->
        if item.typeConstant is typeConstant
          slugProp = slugProps[item.bongo_.constructorName]
          itemWeWant = item[slugProp] is slug

    return itemWeWant


  viewAppended: ->

    super

    # @addHotTopics()
    @addFollowedTopics()
    @addConversations()
    @addMessages()
    @addGroupDescription()  unless KD.isKoding()


  addGroupDescription: ->

    { dock } = KD.singletons

    dock.getView().addSubView new GroupDescription


  addPublicFeedLink: ->

    {activityController} = KD.singletons
    # {slug}               = KD.config.entryPoint
    # {socialApiChannelId} = KD.getGroup()

    @addSubView @public = new CustomLinkView
      title    : 'Public Feed'
      href     : '/Activity/Public'
      cssClass : 'kdlistitemview-sidebar-item public-feed-link'
    ,
      # name         : slug
      typeConstant : 'group'
      # groupName    : slug
      # id           : socialApiChannelId ? '1'

    @public.addSubView new KDCustomHTMLView
      cssClass : 'count hidden'
      tagName  : 'cite'
      partial  : '1'


  addHotTopics: ->

    @addSubView @sections.hot = new ActivitySideView
      title      : 'TRENDING'
      cssClass   : 'hot topics hidden'
      itemClass  : SidebarTopicItem
      dataPath   : 'popularTopics'
      delegate   : this
      headerLink : KD.utils.groupifyLink '/Activity/Topic/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPopularTopics
          limit  : 5
        , callback


  addFollowedTopics: ->

    @addSubView @sections.followedTopics = new ActivitySideView
      title      : 'My Feeds'
      cssClass   : 'followed topics'
      itemClass  : SidebarTopicItem
      dataPath   : 'followedChannels'
      delegate   : this
      noItemText : 'You don\'t follow any topics yet.'
      headerLink : KD.utils.groupifyLink '/Activity/Topic/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : 5
        , callback




  addConversations: ->

    @addSubView @sections.conversations = new ActivitySideView
      title      : 'Conversations'
      cssClass   : 'conversations'
      itemClass  : SidebarPinnedItem
      dataPath   : 'pinnedMessages'
      delegate   : this
      noItemText : 'You didn\'t participate in any conversations yet.'
      headerLink : KD.utils.groupifyLink '/Activity/Post/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 5
        , callback


  addMessages: ->

    @addSubView @sections.messages = new ActivitySideView
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