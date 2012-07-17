class JContextMenu extends KDView
  constructor:(options,data)->

    super options,data
    @setClass "jcontextmenu"
    @getSingleton("windowController").addLayer @

    @on 'ReceivedClickElsewhere', =>
      @destroy()

    @on 'ItemIsbeingDestroyed', =>
      @getSingleton("windowController").removeLayer @

    if data
      @treeController = new JContextMenuTreeViewController 
        delegate          : @
      , data
      @addSubView @treeController.getView()
    KDView.appendToDOMBody @

  childAppended:->
    @positionContextMenu()
    super

  positionContextMenu:()->
    event       = @getOptions().event
    mainHeight  = @getSingleton('mainView').getHeight()
    
    top         = event.pageY
    menuHeight  = @getHeight()
    if top + menuHeight > mainHeight
      top = mainHeight - menuHeight - 15

    @getDomElement().css
      width     : "172px"
      top       : top
      left      : event.pageX
