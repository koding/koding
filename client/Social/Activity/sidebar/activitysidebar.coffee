class ActivitySidebar extends KDCustomScrollView


  addEventLogger = (source, eventName) -> source.on eventName, -> log eventName, arguments


  typeMap =
    privatemessage : 'Message'
    topic          : 'Topic'
    post           : 'Post'
    chat           : 'Chat'


  slugProps =
    SocialMessage : 'slug'
    SocialChannel : 'name'


  # @getRoute = (data) ->

  #   {typeConstant} = data
  #   groupName      = KD.getGroup().slug
  #   groupName      = ''  if groupName is 'koding'
  #   slugProp       = slugProps[data.bongo_.constructorName]

  #   return "#{groupName}/Activity/#{typeMap[typeConstant]}/#{data[slugProp]}"


  # sanitize = (allItems) ->

  #   sanitized = []
  #   for own title, items of allItems
  #     header = new KDObject { title }
  #     items.forEach (item) ->
  #       obj = new KDObject {}, item
  #       obj.parentId = header.getId()
  #       sanitized.push obj
  #     sanitized.push header

  #   return sanitized.reverse()


  constructor: ->

    super

    {
      notificationController
      socialapi
    } = KD.singletons

    addEventLogger notificationController, 'AddedToChannel'
    addEventLogger notificationController, 'RemovedFromChannel'

    @sections     = {}
    @selectedItem = null


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
    then return @public.setClass 'selected'
    else @public.unsetClass 'selected'

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

    @wrapper.addSubView @public = new CustomLinkView
      title    : 'PUBLIC FEED'
      href     : '/Activity/Public'
      cssClass : 'kdlistitemview-sidebar-item public-feed-link'
    ,
      name     : 'koding_public_feed'
      id       : KD.getGroup().socialApiChannelId ? '1'

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
