class JTreeViewController extends KDViewController

  keyMap = ->
    37 : "left"
    38 : "up"
    39 : "right"
    40 : "down"
    8  : "backspace"
    9  : "tab"
    13 : "enter"
    27 : "escape"

  dragHelper = null

  # we're doing this because if we create this image on dragstart
  # it waits to load the image and you don't see the image on first
  # drag, this way we preload it and see it on first drag too.
  cacheDragHelper = do ->

    dragHelper       = document.createElement 'img'
    dragHelper.src   = '/images/multiple-item-drag-helper.png'
    dragHelper.width = 110

  constructor:(options = {},data)->

    o = options
    o.view                      or= (new KDScrollView cssClass : "jtreeview-wrapper")
    o.listViewControllerClass   or= KDListViewController
    o.treeItemClass             or= JTreeItemView
    o.listViewClass             or= JTreeView
    o.itemChildClass            or= null
    o.itemChildOptions          or= {}
    o.nodeIdPath                or= "id"
    o.nodeParentIdPath          or= "parentId"
    o.contextMenu                ?= no
    o.multipleSelection          ?= no
    o.addListsCollapsed          ?= no
    o.sortable                   ?= no
    o.putDepthInfo               ?= yes
    o.addOrphansToRoot           ?= yes
    o.dragdrop                   ?= no

    super o, data

    @listData                     = {}
    @listControllers              = {}
    @nodes                        = {}
    @indexedNodes                 = []
    @selectedNodes                = []


  loadView:(treeView)->

    @initTree @getData()
    @setKeyView()
    @setMainListeners()

    @registerBoundaries()


  registerBoundaries:->
    @boundaries =
      top     : @getView().getY()
      left    : @getView().getX()
      width   : @getView().getWidth()
      height  : @getView().getHeight()

  ###
  HELPERS
  ###

  initTree:(nodes)->

    @removeAllNodes()
    @addNodes nodes

  logTreeStructure:->

    o = @getOptions()
    for index, node of @indexedNodes
      log index, @getNodeId(node), @getNodePId(node), node.depth

  getNodeId:(nodeData)->

    return nodeData[@getOptions().nodeIdPath]

  getNodePId:(nodeData)->

    return nodeData[@getOptions().nodeParentIdPath]

  getPathIndex:(targetPath)->
    for node, index in @indexedNodes
      return index if @getNodeId(node) is targetPath
    return -1

  repairIds:(nodeData)->

    options = @getOptions()
    idPath  = options.nodeIdPath
    pIdPath = options.nodeParentIdPath

    nodeData[idPath] or= @utils.getUniqueId()
    nodeData[idPath]   = "#{@getNodeId nodeData}"
    nodeData[pIdPath]  = if @getNodePId nodeData then "#{@getNodePId nodeData}" else "0"

    @nodes[@getNodeId nodeData] = {}

    if options.putDepthInfo
      if @nodes[nodeData[pIdPath]]
        nodeData.depth = @nodes[nodeData[pIdPath]].getData().depth + 1
      else
        nodeData.depth = 0

    if nodeData[pIdPath] isnt "0" and not @nodes[nodeData[pIdPath]]
      if options.addOrphansToRoot then nodeData[pIdPath] = "0" else nodeData = no

    return nodeData

  isNodeVisible:(nodeView)->

    nodeData = nodeView.getData()
    parentNode = @nodes[@getNodePId nodeData]
    if parentNode
      if parentNode.expanded
        @isNodeVisible parentNode
      else
        return no
    else
      return yes


  areSibling:(node1, node2)->

    node1PId = @getNodePId node1.getData()
    node2PId = @getNodePId node2.getData()

    return node1PId is node2PId

  ###
  DECORATORS
  ###

  setFocusState:->

    view = @getView()
    KD.getSingleton("windowController").addLayer view
    view.unsetClass "dim"

  setBlurState:->

    view = @getView()
    KD.getSingleton("windowController").removeLayer view
    view.setClass "dim"

  ###
  CRUD OPERATIONS FOR NODES
  ###

  # Following Code is partially broken
  # we need to rewrite it at some point ~ GG
  # We're not using it right now but when we decided to use it
  # we need to use it to guess index of node for indexedNodes
  #
  # guessIndex:(nodeData, parentId, index)->
  #   parentIndex = @getPathIndex(parentId)
  #   treeIndex   = parentIndex + index

  #   prevItem  = @indexedNodes[treeIndex - 1]
  #   currItem  = @indexedNodes[treeIndex]
  #   nextItem  = @indexedNodes[treeIndex + 1]

  #   return treeIndex unless nextItem

  #   return treeIndex if index          is 0                           or \
  #                       prevItem.depth >= nodeData.depth              or \
  #                       treeIndex      is parentIndex                 or \
  #                      (treeIndex - 1  is parentIndex and index > 1)  or \
  #                       nextItem.depth <= nodeData.depth

  #   for i in [0..@indexedNodes.length]
  #     nextIndex = treeIndex + 1 + i
  #     nextItem  = @indexedNodes[nextIndex]
  #     return nextIndex - 1 unless nextItem
  #     return nextIndex - 1 if nextItem.depth is nodeData.depth

  #   return 0

  addNode:(nodeData, index)->

    # This methods index option is not usable for now ~ FIXME GG

    return if @nodes[@getNodeId nodeData]
    nodeData = @repairIds nodeData
    return unless nodeData

    @getData().push nodeData unless nodeData in @getData()

    @registerListData nodeData
    parentId = @getNodePId nodeData

    if @listControllers[parentId]?
      list = @listControllers[parentId].getListView()
    else
      list = @createList(parentId).getListView()
      @addSubList @nodes[parentId], parentId

    list.addItem nodeData

    # Enable this to make indexedNodes work correctly with indexes ~ GG
    #
    # if index >= 0
    #   KD.time "Starting to guess"
    #   log "INDEX", index = @guessIndex nodeData, parentId, index
    #   KD.timeEnd "Starting to guess"

    @addIndexedNode nodeData

  addNodes:(nodes)->
    @addNode node for node in nodes

  removeNode:(id)->

    nodeIndexToRemove = null
    for nodeData, index in @getData()
      if @getNodeId(nodeData) is id
        @removeIndexedNode nodeData
        nodeIndexToRemove = index

    if nodeIndexToRemove?
      nodeToRemove = @getData().splice(nodeIndexToRemove, 1)[0]
      @removeChildNodes id
      parentId = @getNodePId nodeToRemove
      # self remove
      @listControllers[parentId].getListView().removeItem @nodes[id]
      # remove reference
      delete @nodes[id]

  removeNodeView:(nodeView)->

    @removeNode @getNodeId nodeView.getData()

  removeAllNodes:->

    for id, listController of @listControllers
      listController.itemsOrdered.forEach @bound 'removeNodeView'
      listController?.getView().destroy()
      delete @listControllers[id]
      delete @listData[id]

    @nodes           = {}
    @listData        = {}
    @indexedNodes    = []
    @selectedNodes   = []
    @listControllers = {}

  removeChildNodes:(id)->

    childNodeIdsToRemove = []
    for nodeData, index in @getData()
      if @getNodePId(nodeData) is id
        childNodeIdsToRemove.push @getNodeId(nodeData)

    for childNodeId in childNodeIdsToRemove
      @removeNode childNodeId

    @listControllers[id]?.getView().destroy()
    delete @listControllers[id]
    delete @listData[id]

  nodeWasAdded:(nodeView)->

    nodeData = nodeView.getData()
    nodeView.$().attr "draggable","true" if @getOptions().dragdrop
    {id, parentId} = nodeData
    @nodes[@getNodeId nodeData] = nodeView
    if @nodes[@getNodePId nodeData]
      @expand @nodes[@getNodePId nodeData] unless @getOptions().addListsCollapsed
      # todo: make decoration with events
      @nodes[@getNodePId nodeData].decorateSubItemsState()
    return unless @listControllers[id]
    @addSubList nodeView, id

  getChildNodes :(aParentNode)->
    children = []
    @indexedNodes.forEach (node, index)=>
      if @getNodePId(node) is @getNodeId(aParentNode)
        children.push {node, index}
    if children.length then children else no

  getPreviousNeighbor: (aParentNode)->
    neighbor = aParentNode
    children = @getChildNodes aParentNode
    if children
      lastChild = children.last
      neighbor = @getPreviousNeighbor lastChild.node
    return neighbor

  addIndexedNode:(nodeData, index)->

    if index >= 0
      @indexedNodes.splice index + 1, 0, nodeData
      return

    # if node parent is present
    parentNodeView = @nodes[@getNodePId nodeData]
    if parentNodeView
      prevNeighbor  = @getPreviousNeighbor parentNodeView.getData()
      neighborIndex = @indexedNodes.indexOf prevNeighbor
      @indexedNodes.splice neighborIndex + 1, 0, nodeData
    else
      @indexedNodes.push nodeData

  removeIndexedNode:(nodeData)->

    if nodeData in @indexedNodes
      index = @indexedNodes.indexOf nodeData
      # Disable this for now, useless for most cases, FIXME GG
      # @selectNode @nodes[@getNodeId @indexedNodes[index-1]] if index-1 >= 0
      @indexedNodes.splice index, 1
      # todo: make decoration with events
      if @nodes[@getNodePId nodeData] and not \
        @getChildNodes(@nodes[@getNodePId nodeData].getData())
          @nodes[@getNodePId nodeData].decorateSubItemsState(no)


  ###
  CREATING LISTS
  ###

  registerListData:(node)->

    parentId = @getNodePId(node)
    @listData[parentId] or= []
    @listData[parentId].push node

  createList:(listId, listItems)->

    options = @getOptions()
    @listControllers[listId] = new options.listViewControllerClass
      id                 : "#{@getId()}_#{listId}"
      wrapper            : no
      scrollView         : no
      selection          : options.selection ? no
      multipleSelection  : options.multipleSelection ? no
      view               : new options.listViewClass
        tagName          : "ul"
        type             : options.type
        itemClass        : options.treeItemClass
        itemChildClass   : options.itemChildClass
        itemChildOptions : options.itemChildOptions
    , items : listItems

    @setListenersForList listId
    return @listControllers[listId]

  addSubList:(nodeView, id)->

    o = @getOptions()
    listToBeAdded = @listControllers[id].getView()
    if nodeView
      nodeView.$().after listToBeAdded.$()
      listToBeAdded.parentIsInDom = yes
      listToBeAdded.emit 'viewAppended'
      if o.addListsCollapsed
        @collapse nodeView
      else
        @expand nodeView
    else
      @getView().addSubView listToBeAdded


  ###
  REGISTERING LISTENERS
  ###

  setMainListeners:->

    KD.getSingleton("windowController").on "ReceivedMouseUpElsewhere", (event)=> @mouseUp event

    @getView().on "ReceivedClickElsewhere", => @setBlurState()

  setListenersForList:(listId)->

    @listControllers[listId].getView().on 'ItemWasAdded', (view, index)=>
      @setItemListeners view, index

    @listControllers[listId].on "ItemSelectionPerformed", (listController, {event, items})=>
      @organizeSelectedNodes listController, items, event

    @listControllers[listId].on "ItemDeselectionPerformed", (listController, {event, items})=>
      @deselectNodes listController, items, event


    @listControllers[listId].getListView().on 'KeyDownOnTreeView', (event)=> @keyEventHappened event

  setItemListeners:(view, index)->

    view.on "viewAppended", @nodeWasAdded.bind @, view

    mouseEvents = ["dblclick", "click", "mousedown", "mouseup", "mouseenter", "mousemove"]

    if @getOptions().contextMenu
      mouseEvents.push "contextmenu"

    if @getOptions().dragdrop
      mouseEvents = mouseEvents.concat ["dragstart", "dragenter", "dragleave", "dragend", "dragover", "drop"]

    view.on mouseEvents, (event)=> @mouseEventHappened view, event


  ###
  NODE SELECTION
  ###


  organizeSelectedNodes:(listController, nodes, event = {})->

    unless (event.metaKey or event.ctrlKey or event.shiftKey) and @getOptions().multipleSelection
      @deselectAllNodes(listController)

    for node in nodes
      unless node in @selectedNodes
        @selectedNodes.push node

  deselectNodes:(listController, nodes, event)->

    for node in nodes
      if node in @selectedNodes
        @selectedNodes.splice @selectedNodes.indexOf(node), 1

  deselectAllNodes:(exceptThisController)->

    for own id, listController of @listControllers
      if listController isnt exceptThisController
        listController.deselectAllItems()
    @selectedNodes = []

  selectNode:(nodeView, event, setFocus = yes)->

    return unless nodeView
    if setFocus then @setFocusState()
    @listControllers[@getNodePId nodeView.getData()].selectItem nodeView, event

  deselectNode:(nodeView, event)->

    @listControllers[@getNodePId nodeView.getData()].deselectSingleItem nodeView, event

  selectFirstNode:->

    @selectNode @nodes[@getNodeId @indexedNodes[0]]

  selectNodesByRange:(node1, node2)->

    indicesToBeSliced = [@indexedNodes.indexOf(node1.getData()), @indexedNodes.indexOf(node2.getData())]
    indicesToBeSliced.sort (a, b)-> a - b
    itemsToBeSelected = @indexedNodes.slice indicesToBeSliced[0], indicesToBeSliced[1] + 1
    for node in itemsToBeSelected
      @selectNode @nodes[@getNodeId node], shiftKey : yes

  ###
  COLLAPSE / EXPAND
  ###

  toggle:(nodeView)->

    if nodeView.expanded then @collapse nodeView else @expand nodeView

  expand:(nodeView)->

    nodeData = nodeView.getData()
    nodeView.expand()
    @listControllers[@getNodeId nodeData]?.getView().expand()

  collapse:(nodeView)->

    nodeData = nodeView.getData()
    @listControllers[@getNodeId nodeData]?.getView().collapse =>
      nodeView.collapse()


  ###
  DND UI FEEDBACKS
  ###

  # THESE 3 METHODS BELOW SHOULD BE REFACTORRED MAKES THE UI HORRIBLY SLUGGISH ON DND - Sinan 07/2012

  showDragOverFeedback: do ->
    _.throttle (nodeView, event)->

      # log "show", nodeView.getData().name
      nodeData = nodeView.getData()
      if nodeData.type isnt "file"
        nodeView.setClass "drop-target"
      else
        @nodes[nodeData.parentPath]?.setClass "drop-target"
        @listControllers[nodeData.parentPath]?.getListView().setClass "drop-target"

      nodeView.setClass "items-hovering"

    , 100

  clearDragOverFeedback: do ->
    _.throttle (nodeView, event)->

      # log "clear", nodeView.getData().name
      nodeData = nodeView.getData()
      if nodeData.type isnt "file"
        nodeView.unsetClass "drop-target"
      else
        @nodes[nodeData.parentPath]?.unsetClass "drop-target"
        @listControllers[nodeData.parentPath]?.getListView().unsetClass "drop-target"

      nodeView.unsetClass "items-hovering"

    , 100

  clearAllDragFeedback: ->

    @utils.wait 101, =>
      @getView().$('.drop-target').removeClass "drop-target"
      @getView().$('.items-hovering').removeClass "items-hovering"
      listController.getListView().unsetClass "drop-target" for path, listController of @listControllers
      nodeView.unsetClass "items-hovering drop-target" for path, nodeView of @nodes

  ###
  HANDLING MOUSE EVENTS
  ###


  mouseEventHappened:(nodeView, event)->

    switch event.type
      when "mouseenter"  then @mouseEnter nodeView, event
      when "dblclick"    then @dblClick nodeView, event
      when "click"       then @click nodeView, event
      when "mousedown"   then @mouseDown nodeView, event
      when "mouseup"     then @mouseUp nodeView, event
      when "mousemove"   then @mouseMove nodeView, event
      when "contextmenu" then @contextMenu nodeView, event
      when "dragstart"   then @dragStart nodeView, event
      when "dragenter"   then @dragEnter nodeView, event
      when "dragleave"   then @dragLeave nodeView, event
      when "dragover"    then @dragOver nodeView, event
      when "dragend"     then @dragEnd nodeView, event
      when "drop"        then @drop nodeView, event

  dblClick:(nodeView, event)->

    @toggle nodeView

  click:(nodeView, event)->

    if /arrow/.test event.target.className
      @toggle nodeView
      return @selectedItems

    @lastEvent = event
    @deselectAllNodes() unless (event.metaKey or event.ctrlKey or event.shiftKey) and @getOptions().multipleSelection

    if nodeView?
      if event.shiftKey and @selectedNodes.length > 0 and @getOptions().multipleSelection
        @selectNodesByRange @selectedNodes[0], nodeView
      else
        @selectNode nodeView, event

    return @selectedItems

  contextMenu:(nodeView, event)->

  mouseDown:(nodeView, event)->

    @lastEvent = event
    unless nodeView in @selectedNodes
      @mouseIsDown = yes
      @cancelDrag = yes
      @mouseDownTempItem = nodeView
      @mouseDownTimer = setTimeout =>
        @mouseIsDown = no
        @cancelDrag = no
        @mouseDownTempItem = null
        @selectNode nodeView, event
      , 1000

    else
      @mouseIsDown = no
      @mouseDownTempItem = null

  mouseUp:(event)->

    clearTimeout @mouseDownTimer
    @mouseIsDown = no
    @cancelDrag = no
    @mouseDownTempItem = null

  mouseEnter:(nodeView, event)->

    clearTimeout @mouseDownTimer
    if @mouseIsDown and @getOptions().multipleSelection
      @cancelDrag = yes
      @deselectAllNodes() unless (event.metaKey or event.ctrlKey or event.shiftKey) and @getOptions().multipleSelection
      @selectNodesByRange @mouseDownTempItem, nodeView

  ###
  HANDLING DND
  ###

  dragStart: (nodeView, event)->

    if @cancelDrag
      event.preventDefault()
      event.stopPropagation()
      return no

    @dragIsActive = yes
    e = event.originalEvent
    e.dataTransfer.effectAllowed = 'copyMove' # only dropEffect='copy' will be dropable

    # We need to look it at later FIXME GG
    # transferredData = (JSON.stringify node.getData() for node in @selectedNodes)
    transferredData = (@getNodeId node.getData() for node in @selectedNodes)

    e.dataTransfer.setData('Text', transferredData.join()) # required otherwise doesn't work

    if @selectedNodes.length > 1
      e.dataTransfer.setDragImage dragHelper, -10, 0

    nodeView.setClass "drag-started"

  dragEnter: (nodeView, event)->
    @emit "dragEnter", nodeView, event

  dragLeave: (nodeView, event)->
    @clearAllDragFeedback()
    @emit "dragLeave", nodeView, event

  dragOver: (nodeView, event)->
    @emit "dragOver", nodeView, event

  dragEnd: (nodeView, event)->

    @dragIsActive = no
    nodeView.unsetClass "drag-started"
    @clearAllDragFeedback()
    @emit "dragEnd", nodeView, event

  drop: (nodeView, event)->

    @dragIsActive = no
    event.preventDefault()
    event.stopPropagation()
    @emit "drop", nodeView, event
    no

  ###
  HANDLING KEY EVENTS
  ###

  setKeyView:->

    if @listControllers[0]
      KD.getSingleton("windowController").setKeyView @listControllers[0].getListView()

  keyEventHappened:(event)->

    key = keyMap()[event.which]
    [nodeView] = @selectedNodes

    @emit "keyEventPerformedOnTreeView", event

    return unless nodeView

    switch key
      when "down","up"
        event.preventDefault()
        nextNode = @["perform#{key.capitalize()}Key"] nodeView, event
        @getView().scrollToSubView?(nextNode) if nextNode
      when "left"      then @performLeftKey nodeView, event
      when "right"     then @performRightKey nodeView, event
      when "backspace" then @performBackspaceKey nodeView, event
      when "enter"     then @performEnterKey nodeView, event
      when "escape"    then @performEscapeKey nodeView, event
      when "tab"       then return no

  performDownKey:(nodeView, event)->

    if @selectedNodes.length > 1
      nodeView = @selectedNodes[@selectedNodes.length-1]
      unless (event.metaKey or event.ctrlKey or event.shiftKey) and @getOptions().multipleSelection
        @deselectAllNodes()
        @selectNode nodeView

    nodeData = nodeView.getData()

    nextIndex = @indexedNodes.indexOf(nodeData)+1
    if @indexedNodes[nextIndex]
      nextNode = @nodes[@getNodeId @indexedNodes[nextIndex]]
      if @isNodeVisible nextNode
        if nextNode in @selectedNodes
          @deselectNode @nodes[@getNodeId nodeData]
        else
          @selectNode nextNode, event
          return nextNode
      else
        @performDownKey nextNode, event

  performUpKey:(nodeView, event)->

    if @selectedNodes.length > 1
      nodeView = @selectedNodes[@selectedNodes.length-1]
      unless (event.metaKey or event.ctrlKey or event.shiftKey) and @getOptions().multipleSelection
        @deselectAllNodes()
        @selectNode nodeView

    nodeData = nodeView.getData()

    nextIndex = @indexedNodes.indexOf(nodeData)-1
    if @indexedNodes[nextIndex]
      nextNode = @nodes[@getNodeId @indexedNodes[nextIndex]]
      if @isNodeVisible nextNode
        if nextNode in @selectedNodes
          @deselectNode @nodes[@getNodeId nodeData]
        else
          @selectNode nextNode, event
      else
        @performUpKey nextNode, event
    return nextNode

  performRightKey:(nodeView, event)->

    @expand nodeView
    # o = @getOptions()
    # @addNode
    #   title     : "some title"
    #   parentId  : @getNodeId nodeData

  performLeftKey:(nodeView, event)->

    nodeData = nodeView.getData()
    if @nodes[@getNodePId nodeData]
      parentNode = @nodes[@getNodePId nodeData]
      @selectNode parentNode
    return parentNode

  performBackspaceKey:(nodeView, event)->

    # nodeData = nodeView.getData()
    # @removeNode @getNodeId nodeData

  performEnterKey:(nodeView, event)->

    # nodeData = nodeView.getData()
    # nodeView.toggle()
    # @listControllers[@getNodeId nodeData]?.getView().toggle()

  performEscapeKey:(nodeView, event)->

