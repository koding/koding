class ActivityAppView extends KDView

  {isKoding, isGroup, isMember} = KD
  {permissions}                 = KD.config

  canListMembers = -> 'list members' in permissions
  isPrivateGroup = -> not isKoding() and isGroup()

  constructor:(options = {}, data)->

    options.cssClass   = 'content-page activity clearfix'
    # options.cssClass   = KD.utils.curry 'group', options.cssClass  unless isKoding()
    options.domId      = 'content-page-activity'

    super options, data

    {
      appStorageController
      windowController
    }             = KD.singletons
    {entryPoint}  = KD.config
    @_lastMessage = null

    @appStorage  = appStorageController.storage 'Activity', '2.0'
    # @groupHeader = new FeedCoverPhotoView
    @sidebar     = new ActivitySidebar tagName : 'aside', delegate : this
    @tabs        = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes

    @appStorage.setValue 'liveUpdates', off

    # windowController.on 'ScrollHappened', @bound 'scroll'  unless isKoding()



  lazyLoadThresholdReached: -> @tabs.getActivePane()?.emit 'LazyLoadThresholdReached'


  viewAppended: ->

    # @addSubView @groupHeader  unless isKoding()
    @addSubView @sidebar
    @addSubView @tabs


  scroll: ->

    if window.scrollY > 316
    then @setClass 'fixed'
    else @unsetClass 'fixed'


  # type: [public|topic|post|message|chat|null]
  # slug: [slug|id|name]
  open: (type, slug) ->

    {socialapi, router, notificationController} = KD.singletons


    kallback = (data) =>
      name = if slug then "#{type}-#{slug}" else type
      pane = @tabs.getPaneByName name

      unless @sidebar.selectedItem
        @sidebar.selectItemByRouteOptions type, slug

      if pane
      then @tabs.showPane pane
      else @createTab name, data

    @sidebar.selectItemByRouteOptions type, slug
    item = @sidebar.selectedItem

    if type is 'public'
      item = @sidebar.public
      kallback item.getData()

    else if not item
      type_ = switch type
        when 'message' then 'privatemessage'
        when 'post'    then 'activity'
        else type

      socialapi.cacheable type_, slug, (err, data) =>
        if err then router.handleNotFound router.getCurrentPath()
        else
          @sidebar.addItem data
          kallback data

    else
      kallback item.getData()


  openNext: ->

    items    = @sidebar.getItems()
    selected = @sidebar.selectedItem

    index = items.indexOf selected
    next  = index + 1
    next  = Math.min next, items.length - 1
    item  = items[next]

    {route, href} = item.getOptions()

    KD.singletons.router.handleRoute route or href


  openPrev: ->

    items    = @sidebar.getItems()
    selected = @sidebar.selectedItem

    index = items.indexOf selected
    prev  = Math.min Math.max(0, index - 1), items.length - 1
    item  = items[prev]

    {route, href} = item.getOptions()

    KD.singletons.router.handleRoute route or href


  createTab: (name, data) ->

    channelId = data.id
    type      = data.typeConstant

    paneClass = switch type
      when 'topic' then TopicMessagePane
      else MessagePane

    itemClass = switch type
      when 'privatemessage' then PrivateMessageListItemView
      else ActivityListItemView

    @tabs.addPane pane = new paneClass {name, itemClass, type, channelId}, data

    return pane


  refreshTab: (name) ->

    pane = @tabs.getPaneByName name

    pane?.refresh()

    return pane


  showNewMessageModal: ->

    @open 'public'  unless @tabs.getActivePane()

    bounds = @sidebar.sections.messages.options.headerLink.getBounds()

    top      = bounds.y - 310
    left     = bounds.x + bounds.w + 40
    arrowTop = 310 + (bounds.h / 2) - 10 #10 = arrow height
    arrowTop = arrowTop + top  if top < 0

    modal = new PrivateMessageModal
      delegate     : this
      _lastMessage : @_lastMessage
      position     :
        top        : Math.max top, 0
        left       : left
      arrowTop     : arrowTop

    return modal


  showAllTopicsModal: ->

    @open 'public'  unless @tabs.getActivePane()

    return new YourTopicsModal delegate : this


  showAllConversationsModal: ->

    @open 'public'  unless @tabs.getActivePane()

    return new ConversationsModal delegate : this
