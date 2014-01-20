class NavigationLink extends KDListItemView
  constructor:(options = {}, data={})->
    data.type        or= ''
    options.tagName  or= 'a'
    options.type     or= 'main-nav'
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

    @icon.hide()  if @name in appsHasIcon

    @quitAppLink = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "quit-app-link"
      partial  : "close"
      click    : =>
        appManager = KD.singleton('appManager')
        router     = KD.singleton('router')

        appManager.quitByName @name

        if appManager.getFrontApp().getOptions().name is @name
          router.back()

    @on "DragStarted", @bound 'dragStarted'

  setState:(state = 'initial')->

    states = 'running failed loading'
    @unsetClass states
    if state in states.split ' ' then @setClass state
    if state is 'running'
      @setClass 'running-initial'
      @once 'mouseleave', => @unsetClass 'running-initial'


  click:(event)->
    KD.utils.stopDOMEvent event
    {appPath, title, path, type, topLevel} = @getData()

    # This check is for custom items which isn't connected to an app
    # or if the item is a separator
    return false  if not path or @positionChanged() or (event.target is @quitAppLink.getElement())

    mc = KD.getSingleton 'mainController'
    mc.emit "NavigationLinkTitleClick",
      pageName  : title
      appPath   : appPath or title
      path      : path
      topLevel  : topLevel
      navItem   : this

  viewAppended:->
    JView::viewAppended.call this
    @keepCurrentPosition()

  pistachio:->
    """
      {{> @icon}}
      <span class='icon'></span>
      <cite>#{@name}</cite>
      {{> @quitAppLink}}
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
