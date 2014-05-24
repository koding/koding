class ActivityAppView extends KDScrollView

  JView.mixin @prototype

  headerHeight = 0

  {entryPoint, permissions, roles} = KD.config

  isGroup        = -> entryPoint?.type is 'group'
  isKoding       = -> entryPoint?.slug is 'koding'
  isMember       = -> 'member' in roles
  canListMembers = -> 'list members' in permissions
  isPrivateGroup = -> not isKoding() and isGroup()


  constructor:(options = {}, data)->

    options.cssClass   = 'content-page activity'
    options.domId      = 'content-page-activity'

    super options, data

    {entryPoint}           = KD.config
    {appStorageController} = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'
    @sidebar    = new ActivitySidebar tagName : 'aside', delegate : this
    @tabs       = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes

    @appStorage.setValue 'liveUpdates', off



  lazyLoadThresholdReached: -> @tabs.getActivePane().emit 'LazyLoadThresholdReached'


  viewAppended: ->

    @addSubView @sidebar
    @addSubView @tabs


  open: (type, slug) ->

    item = @sidebar.getItemById(id) or @sidebar.public
    data = item.getData()
    id   = data.id + ''
    name = "#{type}-#{id}"
    log name, data
    pane = @tabs.getPaneByName name

    if pane
    then @tabs.showPane pane
    else @createTab data

    @emit 'PaneRequested', type, id


  createTab: (data) ->

    channelId = data.id
    type      = data.typeConstant
    name      = "#{type}-#{channelId}"

    @tabs.addPane pane = new MessagePane {name, type, channelId}, data

    return pane


  refreshTab: (data) ->

    channelId = data.id
    type      = data.typeConstant
    name      = "#{type}-#{channelId}"
    pane      = @tabs.getPaneByName name

    pane.refresh()

    return pane
