class IDE.StatusBarAvatarView extends AvatarView

  INTENT_DELAY = 177

  constructor: (options = {}, data) ->

    options.bind = KD.utils.curry 'mouseenter mouseleave', options.bind

    super options, data

    @intentTimer = null


  click: (event) ->

    KD.utils.stopDOMEvent event
    @showMenu()

    return no


  mouseEnter: -> @intentTimer = KD.utils.wait INTENT_DELAY, @bound 'showMenu'

  mouseLeave: -> KD.utils.killWait @intentTimer  if @intentTimer

  showMenu: ->

    return  if @menu

    { appManager } = KD.singletons
    { rtm }        = appManager.getFrontApp()
    { profile }    = @getData()
    changes        = rtm.getFromModel("#{nickname}Snapshot")?.values() or []
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

    menuWidth       = 172
    statusBarHeight = 40

    @menu = new KDContextMenu
      cssClass    : 'dark statusbar-files'
      event       : event
      delegate    : this
      x           : @getX()
      y           : @getY()
      offset      :
        top       : -5000
        left      : -86
      arrow       :
        placement : 'bottom'
        margin    : menuWidth / 2
    , menuItems


    KD.utils.wait 200, =>
      h = @menu.getHeight()
      w = @menu.getWidth()
      top  = -h
      left = @getWidth()/2 - w/2
      @menu.setOption 'offset', {left, top}
      @menu.positionContextMenu()

    @menu.once 'KDObjectWillBeDestroyed', => @menu = null