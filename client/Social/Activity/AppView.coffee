class ActivityAppView extends KDView

  {isKoding, isGroup, isMember} = KD
  {permissions}                 = KD.config

  canListMembers = -> 'list members' in permissions
  isPrivateGroup = -> not isKoding() and isGroup()

  constructor:(options = {}, data)->

    options.cssClass   = 'content-page activity clearfix'
    options.domId      = 'content-page-activity'

    super options, data

    {
      appStorageController
      windowController
      mainView
    }             = KD.singletons
    {entryPoint}  = KD.config

    @appStorage  = appStorageController.storage 'Activity', '2.0'

    @tabs = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes
    @tabs.unsetClass 'kdscrollview'

    @tabs.on 'PaneDidShow', (pane) =>
      if type = pane.getData()?.typeConstant
        @tabs.setAttribute 'class', KD.utils.curry 'kdview kdtabview', type

    { router, appManager } = KD.singletons

    router.on 'AlreadyHere', (path, options) =>

      [slug] = options.frags

      return  if slug isnt 'Activity'

      router.handleRoute path, { replaceState: yes }


  viewAppended: ->

    # @addSubView @groupHeader  unless isKoding()
    # @addSubView @sidebar
    { mainView } = KD.singletons
    @sidebar     = mainView.activitySidebar
    @addSubView @tabs

    @parent.on 'KDTabPaneActive', =>

      return  unless pane = @tabs.getActivePane()

      KD.utils.defer ->
        pane.applyScrollTops()

      KD.utils.wait 50, -> pane.scrollView.wrapper.emit 'MutationHappened'

    @parent.on 'KDTabPaneInactive', =>

      return  unless pane = @tabs.getActivePane()

      pane.setScrollTops()


  openTab: (data, type, slug) ->

    name = if slug then "#{type}-#{slug}" else type
    pane = @tabs.getPaneByName name

    return @createTab name, data  unless pane

    unless @sidebar.selectedItem
      @sidebar.selectItemByRouteOptions type, slug

    @tabs.showPane pane


  # type: [topic|post|message|chat|null]
  # slug: [slug|id|name]
  open: (type, slug) ->

    {socialapi, router} = KD.singletons

    @sidebar.selectItemByRouteOptions type, slug
    item = @sidebar.selectedItem

    return @openTab item.getData(), type, slug  if item

    type_ = switch type
      when 'message' then 'privatemessage'
      when 'post'    then 'activity'
      else type

    socialapi.cacheable type_, slug, (err, data) =>

      return router.handleNotFound router.getCurrentPath()  if err

      @sidebar.addItem data, 2
      @openTab data, type, slug


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
      when 'topic'          then TopicMessagePane
      when 'privatemessage' then PrivateMessagePane
      when 'post'           then SingleActivityPane
      else
        if name is 'announcement-changelog'
        then AnnouncementPane
        else ActivityPane

    @tabs.addPane pane = new paneClass {name, type, channelId}, data

    pane.on 'LeftChannel', => @tabs.removePane pane

    return pane


  showNewMessageForm: ->

    # @widgetsBar.hide()
    @tabs.addPane pane = (new KDTabPaneView cssClass : 'privatemessage' ), yes
      .addSubView form = new PrivateMessageForm
      .once 'KDObjectWillBeDestroyed', @tabs.lazyBound 'removePane', pane

  showAllTopicsModal: ->

    @open 'topic', 'public'  unless @tabs.getActivePane()

    return new TopicSearchModal delegate : this

  showFollowingTopicsModal: ->

    @open 'topic', 'public'  unless @tabs.getActivePane()

    modalClass = MoreChannelsModal
    {moreLink} = @sidebar.sections.channels

    KD.utils.defer @lazyBound 'showMoreModal', {modalClass, moreLink}


  showAllConversationsModal: ->

    @open 'topic', 'public'  unless @tabs.getActivePane()

    return new ConversationsModal delegate : this


  showAllChatsModal: ->

    @open 'topic', 'public'  unless @tabs.getActivePane()

    modalClass = ChatSearchModal
    {moreLink} = @sidebar.sections.messages

    KD.utils.defer @lazyBound 'showMoreModal', {modalClass, moreLink}


  showMoreModal: ({modalClass, moreLink}) ->

    modal = new modalClass { delegate : this }

    modal.addSubView new KDCustomHTMLView
      cssClass : 'arrow'
      position :
        top    : moreLink.getY()
        left   : moreLink.getX() + moreLink.getWidth()


  getModalArrowPosition: (ref) ->

    top  = ref.getY() - 80
    left = ref.getX() + ref.getWidth() + 10

    if window.innerHeight <= (top + 218)
      top = window.innerHeight - 220

    return {top, left}