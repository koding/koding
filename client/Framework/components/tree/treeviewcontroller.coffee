###
todo:

  - multipleselection is broken with implementing it as optional

###


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
    o.nodeIdPath                or= "id"
    o.nodeParentIdPath          or= "parentId"
    o.contextMenu                ?= no
    o.multipleSelection          ?= no
    o.addListsCollapsed          ?= no
    o.sortable                   ?= no
    o.putDepthInfo               ?= no
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
    @addNode node for node in nodes

  logTreeStructure:->

    o = @getOptions()
    for node in @indexedNodes
      # log @nodes[@getNodeId(node)].expanded, node
      log @getNodeId(node), @getNodePId(node), node.depth

  getNodeId:(nodeData)->

    return nodeData[@getOptions().nodeIdPath]

  getNodePId:(nodeData)->

    return nodeData[@getOptions().nodeParentIdPath]

  repairIds:(nodeData)->

    options = @getOptions()
    idPath  = options.nodeIdPath
    pIdPath = options.nodeParentIdPath

    nodeData[idPath] or= @utils.getUniqueId()
    nodeData[idPath]   = "#{@getNodeId nodeData}"
    nodeData[pIdPath]  = if @getNodePId nodeData then "#{@getNodePId nodeData}" else "0"

    @nodes[@getNodeId nodeData] = {}

    if options.putDepthInfo
      if @nodes[@getNodePId nodeData]
        nodeData.depth = @nodes[@getNodePId(nodeData)].getData().depth + 1
      else
        nodeData.depth = 0

    if @getNodePId(nodeData) isnt "0" and not @nodes[@getNodePId nodeData]
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
  CRUD OPERATIONS FOR NODES
  ###

  addNode:(nodeData, index)->

    nodeData = @repairIds nodeData
    return unless nodeData
    @getData().push nodeData
    @addIndexedNode nodeData
    @registerListData nodeData
    parentId = @getNodePId nodeData

    if @listControllers[parentId]
      list = @listControllers[parentId].getListView()
    else
      list = @createList(parentId).getListView()
      @addSubList @nodes[parentId], parentId

    list.addItem nodeData, index

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

    if @listControllers["0"]
      @listControllers["0"].itemsOrdered.forEach (itemView)=>
        @removeNodeView itemView

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

  addIndexedNode:(nodeData)->

    neighbor = null
    getPreviousNeighbor = (aParentNode)=>
      neighbor = aParentNode
      children = @getChildNodes aParentNode
      if children
        lastChild = children[children.length-1]
        # @selectNode @nodes[@getNodeId lastChild.node]
        neighbor = getPreviousNeighbor lastChild.node

      return neighbor

    # if node parent is present
    parentNodeView = @nodes[@getNodePId nodeData]
    if parentNodeView
      prevNeighbor  = getPreviousNeighbor parentNodeView.getData()
      neighborIndex = @indexedNodes.indexOf prevNeighbor
      @indexedNodes.splice neighborIndex + 1, 0, nodeData
    else
      @indexedNodes.push nodeData

  removeIndexedNode:(nodeData)->

    if nodeData in @indexedNodes
      index = @indexedNodes.indexOf nodeData
      @selectNode @nodes[@getNodeId @indexedNodes[index-1]] if index-1 >= 0
      @indexedNodes.splice index, 1
      # todo: make decoration with events
      if @nodes[@getNodePId nodeData] and not @getChildNodes(@nodes[@getNodePId nodeData].getData())
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
      id             : "#{@getId()}_#{listId}"
      wrapper        : no
      scrollView     : no
      selection      : no
      view           : new options.listViewClass
        tagName      : "ul"
        type         : "jtree"
        subItemClass : options.treeItemClass
    , items : listItems

    @setListenersForList listId
    return @listControllers[listId]

  addSubList:(nodeView, id)->

    o = @getOptions()
    listToBeAdded = @listControllers[id].getView()
    if nodeView
      nodeView.$().after listToBeAdded.$()
      listToBeAdded.parentIsInDom = yes
      listToBeAdded.propagateEvent KDEventType: 'viewAppended'
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

    @listenTo
      KDEventTypes       : "ReceivedMouseUpElsewhere"
      listenedToInstance : @getSingleton("windowController")
      callback           : (windowController, event)-> @mouseUp windowController, event

  setListenersForList:(listId)->

    @listControllers[listId].getView().on 'ItemWasAdded', (view, index)=>
      @setItemListeners view, index

    @listenTo
      KDEventTypes       : ["ItemSelectionPerformed","ItemDeselectionPerformed"]
      listenedToInstance : @listControllers[listId]
      callback           : (listController, {event, items}, {subscription})=>
        switch subscription.KDEventType
          when "ItemSelectionPerformed"
            @organizeSelectedNodes listController, items, event
          when "ItemDeselectionPerformed"
            @deselectNodes listController, items, event

    @listenTo
      KDEventTypes        : 'KeyDownOnTreeView'
      listenedToInstance  : @listControllers[listId].getListView()
      callback            : (treeview, event)=> @keyEventHappened event

  setItemListeners:(view, index)->

    @listenTo
      KDEventTypes       : "viewAppended"
      listenedToInstance : view
      callback           : (view)=> @nodeWasAdded view


    mouseEvents = ["dblclick", "click", "mousedown", "mouseup", "mouseenter", "mousemove"]

    if @getOptions().contextMenu
      mouseEvents.push "contextmenu"

    if @getOptions().dragdrop
      mouseEvents = mouseEvents.concat ["dragstart", "dragenter", "dragleave", "dragend", "dragover", "drop"]

    @listenTo
      KDEventTypes       : mouseEvents
      listenedToInstance : view
      callback           : (pubInst, event)=> @mouseEventHappened pubInst, event


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

  selectNode:(nodeView, event)->

    return unless nodeView
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

  showDragOverFeedback:(nodeView, event)->

    # log "show", nodeView.getData().name
    nodeData = nodeView.getData()
    if nodeData.type isnt "file"
      nodeView.setClass "drop-target"
    else
      @nodes[nodeData.parentPath]?.setClass "drop-target"
      @listControllers[nodeData.parentPath]?.getListView().setClass "drop-target"

    nodeView.setClass "items-hovering"

  clearDragOverFeedback:(nodeView, event)->

    # log "clear", nodeView.getData().name
    nodeData = nodeView.getData()
    if nodeData.type isnt "file"
      nodeView.unsetClass "drop-target"
    else
      @nodes[nodeData.parentPath]?.unsetClass "drop-target"
      @listControllers[nodeData.parentPath]?.getListView().unsetClass "drop-target"

    nodeView.unsetClass "items-hovering"

  clearAllDragFeedback:->

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

  mouseUp:(pubInst, event)->

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
    transferredData = (@getNodeId node.getData() for node in @selectedNodes)
    e.dataTransfer.setData('Text', transferredData.join()) # required otherwise doesn't work

    if @selectedNodes.length > 1
      e.dataTransfer.setDragImage dragHelper, -10, 0

    # this doesnt work in webkit only firefox

    # items = for node in @selectedNodes
    #   node.getData()
    #
    # options = @getOptions()
    # draggedListController = new KDListViewController
    #   wrapper        : no
    #   scrollView     : no
    #   selection      : no
    #   view           : new JTreeView
    #     tagName      : "ul"
    #     type         : "jtree"
    #     cssClass     : "drag-helper-list"
    #     subItemClass : JTreeItemView
    # , {items}
    #
    # @tempDragList = draggedListController.getView()
    # KDView.appendToDOMBody @tempDragList
    # @tempDragList.$().css top : e.pageY, left : e.pageY
    # draggedList = @tempDragList.$()[0]
    # e.dataTransfer.addElement(draggedList);
    nodeView.setClass "drag-started"

  dragEnter: (nodeView, event)->

    # log event.type

  dragLeave: (nodeView, event)->

    # log event.type

  dragOver: (nodeView, event)->

    no

  dragEnd: (nodeView, event)->

    @dragIsActive = no
    nodeView.unsetClass "drag-started"

  drop: (nodeView, event)->

    @dragIsActive = no
    event.preventDefault()
    event.stopPropagation()
    no

  ###
  HANDLING KEY EVENTS
  ###

  setKeyView:->

    if @listControllers[0]
      @getSingleton("windowController").setKeyView @listControllers[0].getListView()

  keyEventHappened:(event)->

    key = keyMap()[event.which]
    [nodeView] = @selectedNodes

    return unless nodeView

    switch key
      when "down"      then @performDownKey nodeView, event
      when "up"        then @performUpKey nodeView, event
      when "left"      then @performLeftKey nodeView, event
      when "right"     then @performRightKey nodeView, event
      when "backspace" then @performBackspaceKey nodeView, event
      when "enter"     then @performEnterKey nodeView, event
      when "escape"    then @performEscapeKey nodeView, event
      when "tab"       then return no

    switch key
      when "down", "up"
        event.preventDefault()
        @getView().scrollToSubView? nodeView

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

