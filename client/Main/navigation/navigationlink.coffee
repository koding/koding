class NavigationLink extends KDListItemView

  constructor:(options = {}, data={})->

    href = if ep = KD.config.entryPoint then ep.slug + data.path else data.path

    data.type        or= ''
    options.tagName  or= 'a'
    options.type     or= 'main-nav'
    options.draggable  = yes
    options.attributes = {href}
    options.cssClass   = KD.utils.curry @utils.slugify(data.title), options.cssClass

    super options,data

    @name = data.title

    @on "DragStarted", @bound 'dragStarted'

    @on "DragInAction", @bound 'dragInAction'

    @on "DragFinished", @bound 'dragFinished'

  click:(event)->
    KD.utils.stopDOMEvent event
    {appPath, title, path, type, topLevel} = @getData()

    # This check is for custom items which isn't connected to an app
    # or if the item is a separator
    return unless path

    mc = KD.getSingleton 'mainController'
    mc.emit "NavigationLinkTitleClick",
      pageName  : title
      appPath   : appPath or title
      path      : path
      topLevel  : topLevel
      navItem   : this

  partial:(data)->
    "<span class='icon'></span><cite>#{data.title}</cite>"

  dragInAction: (x, y)-> #log x, y

  dragStarted: (event, dragState)->

    @setClass 'no-anim'

  dragFinished: (event, dragState)->

    @unsetClass 'no-anim'