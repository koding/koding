class JContextMenuTreeViewController extends JTreeViewController

  ###
  STATIC CONTEXT
  ###

  uId = 0
  getUId = -> ++uId
  convertToArray = (items, pId = null)->
    results = []

    for title, options of items
      id = null
      if (title.indexOf "customView") is 0
        newItem = { type : 'customView', parentId : pId, view : options }
        results.push newItem
        continue
      if options.children
        id               = getUId()
        options.title    = title
        options.id       = id
        options.parentId = pId
        results.push options
        childrenArr = convertToArray options.children, id
        results = results.concat childrenArr
        if options.separator
          divider = { type : 'separator', parentId : pId }
          results.push divider
        continue

      options.title    = title
      options.parentId = pId
      results.push options

      if options.separator
        divider = { type : 'separator', parentId : pId }
        results.push divider

    return results

  ###
  INSTANCE LEVEL
  ###

  constructor:(options = {},data)->

    o = options
    o.view              or= new KDView cssClass : "context-list-wrapper"
    o.type              or= "contextmenu"
    o.treeItemClass     or= JContextMenuItem
    o.listViewClass     or= JContextMenuTreeView
    o.addListsCollapsed or= yes
    o.putDepthInfo      or= yes
    super o, data
    @expandedNodes        = []

  loadView:->

    super
    @selectFirstNode()  unless @getOptions().lazyLoad

  initTree:(nodes)->

    unless nodes.length
      @setData nodes = convertToArray nodes
    super nodes


  ###
  Helpers
  ###

  repairIds:(nodeData)->

    nodeData.type = "separator" if nodeData.type is "divider"
    super

  ###
  EXPAND / COLLAPSE
  ###

  expand:(nodeView)->

    super
    @emit "NodeExpanded", nodeView
    @expandedNodes.push nodeView if nodeView.expanded

  ###
  NODE SELECTION
  ###

  organizeSelectedNodes:(listController, nodes, event = {})->

    nodeView = nodes[0]

    if @expandedNodes.length
      depth1 = nodeView.getData().depth
      @expandedNodes.forEach (expandedNode)=>
        depth2 = expandedNode.getData().depth
        if depth1 <= depth2
          @collapse expandedNode
    super

  ###
  re-HANDLING MOUSE EVENTS
  ###

  dblClick:(nodeView, event)->

  mouseEnter:(nodeView, event)->

    if @mouseEnterTimeOut
      clearTimeout @mouseEnterTimeOut

    nodeData = nodeView.getData()
    unless nodeData.type is "separator"
      @selectNode nodeView, event
      @mouseEnterTimeOut = setTimeout =>
        @expand nodeView
      , 150

  click:(nodeView, event)->

    nodeData = nodeView.getData()
    return if nodeData.type is "separator" or nodeData.disabled

    @toggle nodeView
    contextMenu = @getDelegate()
    if nodeData.callback and "function" is typeof nodeData.callback
      nodeData.callback.call contextMenu, nodeView, event
    contextMenu.emit "ContextMenuItemReceivedClick", nodeView
    event.stopPropagation()
    no

  ###
  re-HANDLING KEY EVENTS
  ###

  performDownKey:(nodeView, event)->

    nextNode = super nodeView, event
    if nextNode
      nodeData = nextNode.getData()
      if nodeData.type is "separator"
        @performDownKey nextNode, event

  performUpKey:(nodeView, event)->

    nextNode = super nodeView, event
    if nextNode
      nodeData = nextNode.getData()
      if nodeData.type is "separator"
        @performUpKey nextNode, event

    return nextNode

  performRightKey:(nodeView, event)->

    super
    @performDownKey nodeView, event

  performLeftKey:(nodeView, event)->

    parentNode = super nodeView, event
    if parentNode
      @collapse parentNode
    return parentNode

    return nextNode

  performEscapeKey:(nodeView, event)->

    KD.getSingleton("windowController").revertKeyView()
    @getDelegate().destroy()

  performEnterKey:(nodeView, event)->

    KD.getSingleton("windowController").revertKeyView()
    contextMenu = @getDelegate()
    contextMenu.emit "ContextMenuItemReceivedClick", nodeView
    contextMenu.destroy()
    return no
