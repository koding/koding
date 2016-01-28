kd                          = require 'kd'
KDContextMenu               = kd.ContextMenu
FSHelper                    = require 'app/util/fs/fshelper'
AvatarView                  = require 'app/commonviews/avatarviews/avatarview'
IDEChatHeadWatchItemView    = require './idechatheadwatchitemview'
IDEChatHeadReadOnlyItemView = require './idechatheadreadonlyitemview'
IDELayoutManager            = require '../../workspace/idelayoutmanager'


module.exports = class IDEStatusBarAvatarView extends AvatarView

  INTENT_DELAY = 177
  MENU         = null

  constructor: (options = {}, data) ->

    options.bind = kd.utils.curry 'mouseenter mouseleave', options.bind

    super options, data

    @intentTimer   = null
    @nickname      = @getOptions().origin
    { appManager } = kd.singletons

    appManager.tell 'IDE', 'getCollaborationData', (collaborationData) =>

      { watchMap } = collaborationData
      isWatching  = watchMap.indexOf(@nickname) > -1

      @setClass 'watching'  if isWatching


  click: (event) ->

    kd.utils.stopDOMEvent event
    @showMenu()

    return no

  mouseEnter: -> @intentTimer = kd.utils.wait INTENT_DELAY, @bound 'showMenu'

  mouseLeave: -> kd.utils.killWait @intentTimer  if @intentTimer

  showMenu: ->

    return  if MENU and MENU.getOptions().nickname is @nickname

    MENU.destroy()  if MENU

    { appManager } = kd.singletons
    { frontApp }   = appManager
    { rtm }        = frontApp

    menuItems      = {}
    menuData       =
      terminals    : []
      drawings     : []
      browsers     : []
      editors      : []
    menuLabels     =
      terminal     : 'Terminal'
      drawing      : 'Drawing Board'
      browser      : 'Browser'
      editor       : 'Editor'

    hasChanges = no

    panes = frontApp.getSnapshotFromDrive @nickname, yes

    panes.forEach (pane, i) ->

      return  if not pane.context

      { context: { file, paneType } }             = pane
      { editors, terminals, drawings, browsers }  = menuData

      hasChanges = yes

      switch paneType
        when 'editor'   then editors.push   { pane, title : FSHelper.getFileNameFromPath file.path }
        when 'terminal' then terminals.push { pane }
        when 'drawing'  then drawings.push  { pane }
        when 'browser'  then browsers.push  { pane }

    for own section, items of menuData

      items.forEach (item, i) ->
        { context: { paneType } } = item.pane
        title = item.title or "#{paneType.capitalize()} #{i+1}"
        label = menuLabels[paneType]
        menuItems[label] or= children: {}
        targetObj = menuItems[label].children
        targetObj[title] = { title }
        targetObj[title].change = context: item.pane.context
        targetObj[title].callback = (it) ->
          appManager.tell 'IDE', 'createPaneFromChange', it.getData().change
          @destroy()

    menuItems.separator = type: 'separator'  if hasChanges

    appManager.tell 'IDE', 'getCollaborationData', (data) =>

      { amIHost, settings, watchMap, permissions } = data

      isWatching  = watchMap.indexOf(@nickname) > -1
      permission  = permissions.get @nickname

      menuWidth   = 150

      if settings.unwatch or amIHost
        @createWatchToggle menuItems, isWatching

      if amIHost and settings.readOnly
        @createReadOnlyToggle menuItems, permission

      if amIHost
        menuItems.Kick =
          title     : 'Kick'
          callback  : =>
            MENU?.destroy()
            kd.singletons.appManager.tell 'IDE', 'kickParticipant', @getData()

      MENU = new KDContextMenu
        nickname    : @nickname
        cssClass    : 'dark statusbar-files'
        menuWidth   : menuWidth
        delegate    : this
        x           : @getX()
        y           : @getY()
        offset      :
          top       : -5000
          left      : -82
        arrow       :
          placement : 'bottom'
          margin    : menuWidth / 2
      , menuItems


      kd.utils.wait 200, =>
        h = MENU.getHeight()
        w = MENU.getWidth()
        top  = -h - 10
        left = @getWidth()/2 - w/2 - 4 # for an unknown reason - SY
        MENU.setOption 'offset', {left, top}
        MENU.positionContextMenu()

      MENU.once 'KDObjectWillBeDestroyed', => MENU = null


  createWatchToggle: (menuItems, isWatching) ->

    return  unless menuItems
    return  if @hasClass 'offline'

    menuItems.Watch =
      type          : 'customView'
      view          : new IDEChatHeadWatchItemView
        isWatching  : isWatching
        delegate    : this


  createReadOnlyToggle: (menuItems, permission) ->

    return  unless menuItems
    return  if @hasClass 'offline'

    menuItems.ReadOnly =
      type             : 'customView'
      view             : new IDEChatHeadReadOnlyItemView
        permission     : permission
        delegate       : this


  setWatchState: (state) ->

    @toggleClass 'watching'
    methodName = if state then 'watchParticipant' else 'unwatchParticipant'

    kd.singletons.appManager.tell 'IDE', methodName, @nickname

    if state
      kd.singletons.appManager.tell 'IDE', 'showConfirmToSyncLayout', @nickname


  setReadOnlyState: (state) ->

    permission = if state then 'read' else 'edit'
    methodName = 'setParticipantPermission'

    kd.singletons.appManager.tell 'IDE', methodName, @nickname, permission


  destroy: ->

    MENU?.destroy()

    super
