class KDTreeViewController extends KDViewController
  constructor:(options,data)->
    @itemsIndexed = {}
    @itemsStructured = {}
    @archivedItems or= {}
    @itemsOrdered = []
    @selectedItems = []
    # @lastSelectedItemId = 0
    @lists = {}
    @defaultExpandCollapseEvent = "dblClick"
    super options,data


  loadView:(mainView)->
    @instantiateItems @data.items, yes if @data?.items?

  addToIndexedItems:(item)->
    @itemsIndexed[item.getItemDataId()] = item

  removeFromIndexedItems:(item)->
    delete @itemsIndexed[item.getItemDataId()]

  getIndexedItems:()->
    @itemsIndexed

  itemForId:(id)->
    @itemsIndexed[id]
    # return @itemsOrdered[@orderedIndex id]

  # itemForData: (dataItem) ->
  #   for key, item of @itemsIndexed
  #     log 'checking item', item.getData()
  #     if item.getData() is dataItem
  #       return item
  #   warn 'couldnt find item in itemForData', dataItem, @itemsIndexed
  #   null

  itemForData:(dataItem)->
    @itemForId dataItem.id
    # return @itemsOrdered[@orderedIndex dataItem?.id]

  addItemsToStructureAndOrder:(items)->
    for item in items
      @addToIndexedItems item

    changedTree = {}
    baseChanges = []

    for item in items
      #update @structuredItems
      parentItem = (@itemForId [item.getParentNodeId()]) or @itemsStructured
      (parentItem.items or= {})[item.getItemDataId()] = item

      #keep track of parents with new subItems
      if parentItem.getData?
        (changedTree[parentItem.getItemDataId()] or = []).push item
      else
        baseChanges.push item

    #update @itemsOrdered with new items
    @addOrderedSubItems baseChanges
    @addOrderedSubItems subItems, @itemForId id for own id, subItems of changedTree

    {baseChanges, changedTree}

  attachListeners: (itemInstance) ->
    @listenTo
      KDEventTypes        : [ eventType : 'mousedown' ]
      listenedToInstance  : itemInstance
      callback            : @itemClicked
    @listenTo
      KDEventTypes        : [ eventType : 'mouseup' ]
      listenedToInstance  : itemInstance
      callback            : @itemMouseUp
    @listenTo
      KDEventTypes        : [eventType : 'ContextMenuFunction']
      listenedToInstance  : itemInstance
      callback            : (publishingInstance, data)=>
        {functionName, contextMenuDelegate} = data
        # log @,contextMenuDelegate,data
        @[functionName]? contextMenuDelegate, data

  instantiateItems:(dataItems,reloadAll)->
    newItems = for itemData in dataItems
      do =>
        unless reloadAll
          itemInstance = (@itemForData itemData) or @archivedItems[itemData.path]
        unless itemInstance?
          itemInstance = new (@getOptions().itemClass ? KDTreeItemView) delegate : @getView(), itemData


        @attachListeners itemInstance
        itemInstance

    @recreateAndAppendTreeStructure newItems if reloadAll
    newItems

  removeAllItems:()->
    for own id, item of @itemsIndexed
      @removeItem item
    @emptyArchive()
    @itemsStructured = {} #rest of .items taken care of in removeSubItemsOfItem

  recreateAndAppendTreeStructure:(items)->
    {baseChanges, changedTree} = @addItemsToStructureAndOrder items
    @getView().appendTreeItem item for item in baseChanges
    @getView().addToSubTree (parentItem = @itemForId id), @getOrderedSubItems parentItem for own id of changedTree

  addTreeItem:(treeItem)->
    if treeItem instanceof KDTreeItemView
      treeItem
    else
      log "you can't add non-KDTreeItemView type as a list item to KDTreeView"

  refreshSubItemsOfItems:(parentItems,subDataItems)->
    subItems = @instantiateItems subDataItems
    {baseChanges, changedTree} = @addItemsToStructureAndOrder subItems
    @getView().appendTreeItem item for item in baseChanges
    @getView().addToSubTree (parentItem = @itemForId id), @getOrderedSubItems parentItem for own id of changedTree

  addSubItemsOfItems:(parentItems, subDataItems)->
    subItems = @instantiateItems subDataItems
    {baseChanges, changedTree} = @addItemsToStructureAndOrder subItems
    @getView().appendTreeItem item for item in baseChanges
    for own id, items of changedTree
      parentItem = @itemForId id
      @getView().addToSubTree (parentItem), items

  refreshSubItemsOfItem:(parentItem,subDataItems,reloadAll)->
    if !!reloadAll
      @removeSubItemsOfItem parentItem
      @addSubItemsOfItem parentItem,subDataItems,yes
    else
      @archiveSubItemsOfItem parentItem
      @addSubItemsOfItem parentItem,subDataItems, no
      @emptyArchive()

  addSubItemsOfItem:(parentItem,subDataItems,reloadAll)->
    if !!reloadAll
      unless parentItem #if null, add items to base object
        @data.items = [] unless @data.items?
        @data.items = @data.items.concat subDataItems
        return @instantiateItems subDataItems,yes
      parentItem.getData().items = {} unless parentItem.getData().items?
      for item in subDataItems
        parentItem.getData().items[item.title] = item
      newItems = @instantiateItems subDataItems,no
      newItemsData = for item in newItems  # this is just subDataItems?
        item.getData()
      @addItemsToStructureAndOrder newItems,newItemsData,parentItem.getData().id,parentItem.getData()
      @getView().createSubTrees ([parentItem].concat newItems), @
    else
      parentItem.getData().items or= {}
      for item in subDataItems
        #FIXME: change this to path? would that be necessary ever??
        parentItem.getData().items[item.title] = item
      newItems = @instantiateItems subDataItems, no
      @addItemsToStructureAndOrder newItems,subDataItems,parentItem.getData().id,parentItem.getData()
      @getView().createAndUnarchiveSubTrees ([parentItem].concat newItems), @
    newItems

  archiveItems:(items)->
    @archivedItems[item.getData().id] = item for item in items

  archiveSubItemsOfItem:(parentItem)->
    @getView().archiveSubTree parentItem, @
    parentIndex = @orderedIndex parentItem.getData().id
    orderedIndex = (@orderedIndexOfLastSubItem parentIndex) or parentIndex
    @removeItemsAtOrderedIndex parentIndex+1,orderedIndex-parentIndex

  emptyArchive:()->
    for own id, item of @archivedItems
      item.isArchived = no
      # @removeTreeItem item
    @archivedItems = {}

  removeSubItemsOfItem:(parentItem)->
    @getView().removeSubTree parentItem, @
    @removeItem item for own id, item of parentItem.items
    parentItem.items = {}

  removeItem:(item)->
    @removeSubItemsOfItem item
    @getView().removeTreeItem item
    parentItem = @getParentItem forItem:item
    if parentItem? #root item?
      delete parentItem.items[item.getData().id]
      @makeItemSelected parentItem if item.isSelected()

    #remove from various indices
    index = @orderedIndex item.getData().id
    if index? #removeItemsAtOrderedIndex already protected for undefined, but just in case
      @removeItemsAtOrderedIndex index, 1
    @removeFromIndexedItems item

  registerItemType:(treeItem)->
    @addedItemTypes[treeItem.constructor.name] = true

  # expandOrCollapseItem:(publishingInstance,event)->
  #   if publishingInstance.data.items?
  #     if publishingInstance.expanded? and publishingInstance.expanded
  #       @collapseItem(publishingInstance)
  #     else
  #       @expandItem(publishingInstance)

  itemClicked:(publishingInstance,event)->
    @itemMouseDown publishingInstance, event

  itemMouseDown: (publishingInstance,event) ->
    @itemMouseDownIsReceived publishingInstance,event

  itemMouseUp: (publishingInstance,event) ->
    @makeItemSelected(publishingInstance, event)

  makeItemSelected:(publishingInstance)->
    return unless publishingInstance?
    if publishingInstance instanceof KDTreeItemView
      @propagateEvent KDEventType : "ItemSelectedEvent", publishingInstance
      @selectedItems = [publishingInstance]
      publishingInstance.setSelected()
      publishingInstance.highlight()
      @undimSelection()
      @unselectAllExceptJustSelected()
    else
      warn "FIX: ",publishingInstance, "is not a KDTreeItemView, check event listeners!"

  makeAllItemsUnselected:()->
    @selectedItems = []
    for item in @itemsOrdered
      item.setUnselected()
      item.removeHighlight()

  mouseDownOnKDView:(publishingInstance,event)->
    # if $(event.target).closest(".kdtreeview").length < 1
    if publishingInstance.getDomElement().closest(".kdtreeview").length < 1
      @dimSelection()

  dimSelection:()->
    for selectedItem in @selectedItems
      selectedItem.dim()

  undimSelection:()->
    for selectedItem in @selectedItems
      selectedItem.undim()

  goLeft:()->
    item = @selectedItems[0]
    @getView().collapseItem(item) if item.type isnt "file"

  goUp:()->
    currentOrderedIndex = @orderedIndex @selectedItems[0].getData().id
    @selectNextVisibleItem currentOrderedIndex,-1
    @getView().makeScrollIfNecessary @selectedItems[0]

  goRight:()->
    item = @selectedItems[0]
    @getView().expandItem(item) if item.type isnt "file"

  goDown:()->
    currentOrderedIndex = @orderedIndex @selectedItems[0].getData().id
    @selectNextVisibleItem currentOrderedIndex,1
    @getView().makeScrollIfNecessary @selectedItems[0]

  isVisible:(item)->
    return yes unless (parentItem = @itemForId item.getParentNodeId())?
    return no unless parentItem.expanded
    return @isVisible parentItem

  unselectAllExceptJustSelected:()->
    for item in @itemsOrdered.slice 0 #sometimes unselection causes an item to be removed from itemsOrdered (e.g. cancel a rename on Finder)
      justSelected = false
      for selectedItem in @selectedItems
        justSelected = true if selectedItem is item
      unless justSelected
        item.setUnselected()
        item.removeHighlight() unless justSelected

  selectItemAtIndex:(index)-> @selectNextVisibleItem index-1,1

  selectNextVisibleItem:(startIndex,increment,event)->
    return unless (nextItem = @itemsOrdered[startIndex+increment])?
    if @isVisible nextItem
      @makeAllItemsUnselected() unless event?.shiftKey
      if (@selectedItems.indexOf nextItem) is -1 or (@lastSelected.indexOf nextItem) isnt -1
        return @makeItemSelected @itemsOrdered[startIndex+increment],event
    @selectNextVisibleItem startIndex+increment,increment,event

  getParentItem:({forItemData, forItem})->
    if forItem then forItemData = forItem.getData()
    (@itemForId forItemData?.parentId) ? null

  baseItem:(itemData)->
    return itemData unless itemData.parentId?
    return @baseItem (@itemForId itemData.parentId).data

  orderedIndex:(itemId)->
    for item,index in @itemsOrdered
      return index if item.getData().id is itemId#search @itemsOrdered to find the item with matching id

  orderedIndexOfFirstSubItem:(parentOrderedIndex)->
    parentId = @itemsOrdered[parentOrderedIndex]?.getData().id
    return parentOrderedIndex + 1 unless @itemsOrdered[parentOrderedIndex + 1]?.getData().parentId isnt parentId#if an object after parent exists with parentId, return its index
    return undefined#...otherwise return the same parent index

  orderedIndexOfLastSubItem:(parentOrderedIndex)->
    parentId = @itemsOrdered[parentOrderedIndex]?.getData().id
    return @itemsOrdered.length unless parentId?#if parentId is null we're on the top level, so return the max index of @itemsOrdered
    itemsFromParent = []
    itemsFromParent = @itemsOrdered[parentOrderedIndex+1..@itemsOrdered.length-1] if @itemHasAncestor @itemsOrdered[parentOrderedIndex+1]?.getItemDataId(), parentId
    for item,index in itemsFromParent
      return @orderedIndex item.getData().id unless @itemHasAncestor itemsFromParent[index+1]?.getData().id,parentId#otherwise return index of first item after which parentId is no longer the parent
    return undefined

  itemHasAncestor:(itemId,ancestorId)->
    return no unless (parentId = @itemsOrdered[@orderedIndex itemId]?.getParentNodeId())?
    return yes if parentId is ancestorId
    @itemHasAncestor parentId,ancestorId

  numberOfSubItems:(parentOrderedIndex)->
    ((@orderedIndexOfLastSubItem parentOrderedIndex) or parentOrderedIndex) - parentOrderedIndex

  insertOrderedItemsAtIndex:(items,insertionIndex)->
    #now some slicing and splicing
    @itemsOrdered = [].concat(@itemsOrdered[0...insertionIndex], items, @itemsOrdered[insertionIndex..@itemsOrdered.length])

  removeItemsAtOrderedIndex:(itemIndex,numberToRemove = 1)->
    if itemIndex? #sometimes itemIndex is undefined and method removes first item
      @itemsOrdered.splice itemIndex,numberToRemove

  addOrderedSubItems:(items,parentItem)->
    parentOrderedIndex = @orderedIndex parentItem?.getData().id#index of parent object in @itemsOrdered
    insertionIndex = ((@orderedIndexOfLastSubItem parentOrderedIndex) or parentOrderedIndex) + 1#index of last sub item of parent object in @itemsOrdered
    @insertOrderedItemsAtIndex items,insertionIndex

  getOrderedSubItems:(parentItem)->
    parentOrderedIndex = @orderedIndex parentItem.getItemDataId()

    firstSubItemIndex = @orderedIndexOfFirstSubItem parentOrderedIndex
    lastSubItemIndex  = @orderedIndexOfLastSubItem parentOrderedIndex
    if not firstSubItemIndex or not lastSubItemIndex # there is no subitems
      return []
    @itemsOrdered[firstSubItemIndex..lastSubItemIndex] or []

  getOrderedItemsData:(items = @itemsOrdered)->
    for item in items
      item.getData()

  traverseTreeByProperty:(property,pathArray)->
    recursiveSelectNextNode = (children = @itemsStructured.items)=>
      nextNodePropertyValue = pathArray.shift()
      for own id, child of children
        if child.getData()[property] is nextNodePropertyValue
          if pathArray.length < 1 then return id else return recursiveSelectNextNode child.items

    id = recursiveSelectNextNode()
    return id unless $.isArray id
    id = null

  treePathArrayForId:(property,id)->
    pathArray = []

    recursivePushParentPropertyValue = (itemData)=>
      pathArray.unshift itemData[property]
      if (parentId = itemData.parentId)? and (parentData = (@itemForId parentId)?.getData())
        recursivePushParentPropertyValue parentData

    recursivePushParentPropertyValue (@itemForId id).getData()
    pathArray

  ## DELEGATES ##
  itemMouseDownIsReceived:(publishingInstance,event)->

