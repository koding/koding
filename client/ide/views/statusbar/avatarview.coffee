class IDE.StatusBarAvatarView extends AvatarView

  INTENT_DELAY = 177
  MENU         = null

  constructor: (options = {}, data) ->

    options.bind = KD.utils.curry 'mouseenter mouseleave', options.bind

    super options, data

    @intentTimer = null
    @nickname    = @getOptions().origin


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
      terminals : []
      drawings  : []
      browsers  : []
      editors   : []


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
        menuItems[title] = { title }
        menuItems[title].change = item.change
        menuItems[title].callback = (it) ->
          appManager.tell 'IDE', 'createPaneFromChange', it.getData().change
          @destroy()
        menuItems[title].separator = yes  if i is items.length - 1

    appManager.tell 'IDE', 'getCollaborationData', (collaborationData) =>

      { watchMap, amIHost } = collaborationData

      isWatching  = watchMap.indexOf(@nickname) > -1
      title       = if isWatching then 'Unwatch' else 'Watch'
      menuWidth   = 172

      menuItems[title] =
        title    : title
        callback : (item, e) => @setWatchState isWatching, @nickname, item

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


  setWatchState: (isWatching, nickname, item) ->

    isWatching = @latestWatchState or isWatching
    methodName = 'watchParticipant'
    menuLabel  = 'Unwatch'

    if isWatching
      methodName = 'unwatchParticipant'
      menuLabel  = 'Watch'

    KD.singletons.appManager.tell 'IDE', methodName, nickname
    item.updatePartial menuLabel

    @latestWatchState = not isWatching


  destroy: ->

    MENU?.destroy()

    super
