class NavigationLink extends KDListItemView

  JView.mixin @prototype

  NAMES    =
    Editor : 'Ace'

  constructor:(options = {}, data={})->

    {curry, slugify, groupifyLink}   = KD.utils

    data.type        or= ''
    options.tagName  or= 'a'
    options.type     or= 'main-nav'
    options.bind       = curry 'contextmenu', options.bind
    # options.draggable  = yes
    options.cssClass   = curry slugify(data.title), options.cssClass
    options.cssClass   = curry 'no-anim', options.cssClass
    options.attributes = href : groupifyLink data.path

    super options, data

    @name = data.title

    @icon = new KDCustomHTMLView
      cssClass : 'fake-icon'
      partial  : "<span class='logo'>#{@name[0]}</span>"
    @icon.setCss 'backgroundColor', KD.utils.getColorFromString @name

    appsWithIcon = Object.keys(KD.config.apps)
    appsWithIcon.push 'Editor'
    @icon.hide()  if @name in appsWithIcon and not data.useFakeIcon

    @on 'DragStarted', @bound 'dragStarted'


  setState:(state = 'initial')->

    states = 'running failed loading'
    @unsetClass states
    if state in states.split ' ' then @setClass state


  contextMenu:(event)->

    KD.utils.stopDOMEvent event

    {type, path} = @getData()

    items = {}
    items[@name] = disabled  : yes

    if @hasClass 'running'

      items.Close = callback : =>
        contextMenu.destroy()
        @closeApp()

    else

      items.Open = callback : ->
        contextMenu.destroy()
        KD.singletons.router.handleRoute path

    unless type is 'persistent'

      items.Remove = callback : =>
        contextMenu.destroy()
        @getDelegate().removeApp this

    contextMenu   = new KDContextMenu
      cssClass    : 'dock'
      delegate    : this
      menuWidth   : 'auto'
      menuMinWidth: 100
      y           : @getY() + 57
      x           : @getX() - 25
      arrow       :
        margin    : 35
        placement : 'top'
    , items


  closeApp:->

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
      <figure></figure>
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
