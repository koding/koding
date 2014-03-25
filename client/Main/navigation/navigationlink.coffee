class NavigationLink extends KDListItemView

  NAMES    =
    Editor : 'Ace'

  constructor:(options = {}, data={})->
    data.type        or= ''
    options.tagName  or= 'a'
    options.type     or= 'main-nav'
    options.bind       = KD.utils.curry 'contextmenu', options.bind
    # options.tooltip    =
    #   title            : "#{data.title}"
    #   placement        : "bottom"
    #   arrow            : "top"
    options.draggable  = yes
      # axis             : 'xy'
      # containment      : 'parent' #KD.getSingleton('DockController').getView()
    options.cssClass   = KD.utils.curry @utils.slugify(data.title), options.cssClass
    options.cssClass   = KD.utils.curry 'no-anim', options.cssClass
    options.attributes = {}

    {entryPoint} = KD.config
    if entryPoint
      {slug} = entryPoint
      options.attributes.href = "/#{slug}#{data.path}"
    else
      options.attributes.href = data.path

    super options, data

    @name = data.title

    @icon = new KDCustomHTMLView
      cssClass : 'fake-icon'
      partial  : "<span class='logo'>#{@name[0]}</span>"
    @icon.setCss 'backgroundColor', KD.utils.getColorFromString @name

    appsHasIcon = Object.keys(KD.config.apps)
    appsHasIcon.push 'Editor'
    @icon.hide()  if @name in appsHasIcon and not data.useFakeIcon

    @on "DragStarted", @bound 'dragStarted'


  setState:(state = 'initial')->

    states = 'running failed loading'
    @unsetClass states
    if state in states.split ' ' then @setClass state


  click:(event)->
    KD.utils.stopDOMEvent event
    {appPath, title, path, type, topLevel} = @getData()

    # This check is for custom items which isn't connected to an app
    # or if the item is a separator
    return false  if not path or @positionChanged()

    mc = KD.getSingleton 'mainController'
    mc.emit "NavigationLinkTitleClick",
      pageName  : title
      appPath   : appPath or title
      path      : path
      topLevel  : topLevel
      navItem   : this

  contextMenu:(event)->

    KD.utils.stopDOMEvent event

    {type} = @getData()
    items  = null

    log @name

    unless KD.singletons.appManager.appControllers[NAMES[@name] or @name]
      items = Open :
        callback   : =>
          contextMenu.destroy()
          KD.singletons.router.handleRoute @getData().path

    if @hasClass 'running'
      items     or= {}
      items.Close = callback : =>
        contextMenu.destroy()
        @closeApp()

    if type isnt 'persistent'
      items      or= {}
      items.Remove = callback : =>
        contextMenu.destroy()
        @getDelegate().removeApp()

    return  unless items

    contextMenu   = new JContextMenu
      cssClass    : 'dock'
      delegate    : this
      menuWidth   : 100
      y           : @getY() + 57
      x           : @getX() - 25
      arrow       :
        margin    : 47
        placement : 'top'
    , items


  closeApp:->

    # temp fix - SY

    appManager = KD.singleton('appManager')
    router     = KD.singleton('router')

    name = NAMES[@name] or @name
    appManager.quitByName name

    if appManager.getFrontApp().getOptions().name is name
      router.back()

  viewAppended:->
    JView::viewAppended.call this
    @keepCurrentPosition()

  pistachio:->
    """
      {{> @icon}}
      <span class='icon'></span>
      <cite>#{@name}</cite>
    """

  dragStarted: (event, dragState)->

    @keepCurrentPosition()
    @setClass 'no-anim on-top'

  keepCurrentPosition:->

    @_x = @getX()
    @_y = @getY()

    @_rx = @getRelativeX()
    @_ry = @getRelativeY()

  restoreLastPosition:->

    @setX @_rx
    @setY @_ry

  positionChanged:->

    @getRelativeY() isnt @_ry or @getRelativeX() isnt @_rx
