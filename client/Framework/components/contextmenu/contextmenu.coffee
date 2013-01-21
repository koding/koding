class JContextMenu extends KDView

  constructor:(options = {},data)->

    options.cssClass = @utils.curryCssClass "jcontextmenu", options.cssClass

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

    event       = @getOptions().event or {}
    mainHeight  = @getSingleton('mainView').getHeight()

    top         = @getOptions().y or event.pageY or 0
    menuHeight  = @getHeight()
    if top + menuHeight > mainHeight
      top = mainHeight - menuHeight - 15

    @getDomElement().css
      width     : "172px"
      top       : top
      left      : @getOptions().x or event.pageX or 0
