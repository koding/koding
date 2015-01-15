ChatHeadWatchItemView = require './chatheadwatchitemview'


class StatusBarAvatarView extends AvatarView

  INTENT_DELAY = 177
  MENU         = null

  constructor: (options = {}, data) ->

    options.bind = KD.utils.curry 'mouseenter mouseleave', options.bind

    super options, data

    @intentTimer   = null
    @nickname      = @getOptions().origin
    { appManager } = KD.singletons

    appManager.tell 'IDE', 'getCollaborationData', (collaborationData) =>

      { watchMap } = collaborationData
      isWatching  = watchMap.indexOf(@nickname) > -1

      @setClass 'watching'  if isWatching


  click: (event) ->

    KD.utils.stopDOMEvent event
    @showMenu()

    return no

  mouseEnter: -> @intentTimer = KD.utils.wait INTENT_DELAY, @bound 'showMenu'

  mouseLeave: -> KD.utils.killWait @intentTimer  if @intentTimer

  showMenu: ->

    return  if MENU and MENU.getOptions().nickname is @nickname

    MENU.destroy()  if MENU

    { appManager } = KD.singletons
    { rtm }        = appManager.getFrontApp()
    changes        = rtm.getFromModel("#{@nickname}Snapshot")?.values() or []
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


    changes.forEach (change, i) ->

      return if not change.type or not change.context

      { type, context: { file, paneType } }       = change
      { editors, terminals, drawings, browsers }  = menuData

      return unless type is 'NewPaneCreated'

      switch paneType
        when 'editor'   then editors.push   { change, title : FSHelper.getFileNameFromPath file.path }
        when 'terminal' then terminals.push { change }
        when 'drawing'  then drawings.push  { change }
        when 'browser'  then browsers.push  { change }

    for own section, items of menuData

      items.forEach (item, i) ->
        { context: { paneType } } = item.change
        title = item.title or "#{paneType.capitalize()} #{i+1}"
        label = menuLabels[paneType]
        menuItems[label] or= children: {}
        targetObj = menuItems[label].children
        targetObj[title] = { title }
        targetObj[title].change = item.change
        targetObj[title].callback = (it) ->
          appManager.tell 'IDE', 'createPaneFromChange', it.getData().change
          @destroy()

    menuItems.separator = type: 'separator'

    appManager.tell 'IDE', 'getCollaborationData', (collaborationData) =>

      { watchMap, amIHost } = collaborationData

      isWatching  = watchMap.indexOf(@nickname) > -1
      menuWidth   = 172

      unless @hasClass 'offline'
        menuItems.Watch =
          type         : 'customView'
          view         : new ChatHeadWatchItemView
            isWatching : isWatching
            nickname   : @nickname
            delegate   : this

      if amIHost
        menuItems.Kick =
          title     : 'Kick'
          callback  : =>
            MENU?.destroy()
            KD.singletons.appManager.tell 'IDE', 'kickParticipant', @getData()

      MENU = new KDContextMenu
        nickname    : @nickname
        cssClass    : 'dark statusbar-files'
        event       : event
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


      KD.utils.wait 200, =>
        h = MENU.getHeight()
        w = MENU.getWidth()
        top  = -h - 10
        left = @getWidth()/2 - w/2 - 4 # for an unknown reason - SY
        MENU.setOption 'offset', {left, top}
        MENU.positionContextMenu()

      MENU.once 'KDObjectWillBeDestroyed', => MENU = null


  setWatchState: (shouldWatch, nickname) ->

    @toggleClass 'watching'
    methodName = if shouldWatch then 'watchParticipant' else 'unwatchParticipant'

    KD.singletons.appManager.tell 'IDE', methodName, nickname


  destroy: ->

    MENU?.destroy()

    super


module.exports = StatusBarAvatarView
