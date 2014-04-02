class ActivityAppView extends KDView

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


  extractName = (data)-> data.title or data.profile.nickname


  sidebarItemClicked: (item) ->

    data = item.getData()

    if pane = @tabs.getPaneByName extractName data
    then @tabs.showPane pane
    else @createTab data


  createTab: (data) ->

    name = extractName data
    pane = new MessagePane
      name : name

    KD.utils.applyGradient pane, KD.utils.stringToColor(name), KD.utils.stringToColor(name.split('').reverse().join(''))

    @tabs.addPane pane