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
    @sidebar    = new ActivitySidebar tagName : 'aside'
    @tabs       = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes

    @appStorage.setValue 'liveUpdates', off

    {activityController} = KD.singletons
    activityController.on 'SidebarItemClicked', @bound 'sidebarItemClicked'


  viewAppended: ->

    @addSubView @sidebar
    @addSubView @tabs


  sidebarItemClicked: (item) ->

    data = item.getData()
    pane = @tabs.getPaneByName "#{data.id}"

    if pane and pane is @tabs.getActivePane()
    then pane.refresh()
    else if pane
    then @tabs.showPane pane
    else @createTab data


  createTab: (data) ->

    {id, typeConstant} = data

    name      = id
    channelId = name
    type      = typeConstant

    @tabs.addPane pane = new MessagePane {name, type, channelId}, data

    return pane
