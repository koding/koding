class JContextMenu extends KDView

  constructor:(options = {},data)->

    options.cssClass  = @utils.curryCssClass "jcontextmenu", options.cssClass
    options.menuWidth or= 172 

    super options, data

    o = @getOptions()

    @getSingleton("windowController").addLayer @

    @on 'ReceivedClickElsewhere', => @destroy()

    if data
      @treeController = new JContextMenuTreeViewController
        type              : o.type
        view              : o.view
        delegate          : @
        treeItemClass     : o.treeItemClass
        listViewClass     : o.listViewClass
        itemChildClass    : o.itemChildClass
        itemChildOptions  : o.itemChildOptions
        addListsCollapsed : o.addListsCollapsed
        putDepthInfo      : o.putDepthInfo
      , data
      @addSubView @treeController.getView()
      @treeController.getView().on 'ReceivedClickElsewhere', => @destroy()

    KDView.appendToDOMBody @

  childAppended:->

    @positionContextMenu()
    super

  positionContextMenu:()->
    options     = @getOptions()
    event       = options.event or {}
    mainView    = @getSingleton 'mainView'

    mainHeight  = mainView.getHeight()
    mainWidth   = mainView.getWidth()

    menuHeight  = @getHeight()
    menuWidth   = @getWidth()

    top         = options.y or event.pageY or 0
    left        = options.x or event.pageX or 0
    
    if top + menuHeight > mainHeight
      top  = mainHeight - menuHeight - 15

    if left + menuWidth > mainWidth
      left  = mainWidth - menuWidth

    @getDomElement().css
      width     : "#{options.menuWidth}px"
      top       : top
      left      : left