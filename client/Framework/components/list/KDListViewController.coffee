class KDListViewController extends KDViewController

  constructor:(options = {}, data)->

    options.wrapper               ?= yes
    options.scrollView            ?= yes
    options.keyNav                ?= no
    options.multipleSelection     ?= no
    options.selection             ?= yes
    options.startWithLazyLoader   ?= no
    options.itemChildClass        or= null
    options.itemChildOptions      or= {}
    options.showDefaultItem       or= no
    options.defaultItem           or= {}
    options.defaultItem.itemClass or= KDView
    options.defaultItem.options   or= {}
    options.defaultItem.data      or= {}

    options.noItemFoundWidget     or= null
    options.noMoreItemFoundWidget or= null

    defaultOptions = options.defaultItem.options
    defaultOptions.partial        or=  'This list is empty'

    @itemsOrdered                 = [] unless @itemsOrdered
    @itemsIndexed                 = {}
    @selectedItems                = []
    @lazyLoader                   = null

    if options.view
      @setListView listView = options.view
    else
      viewOptions                    = options.viewOptions or {}
      viewOptions.lastToFirst      or= options.lastToFirst
      viewOptions.itemClass        or= options.itemClass
      viewOptions.itemChildClass   or= options.itemChildClass
      viewOptions.itemChildOptions or= options.itemChildOptions

      @setListView listView = new KDListView viewOptions

    if options.scrollView
      @scrollView = new KDScrollView
        lazyLoadThreshold : options.lazyLoadThreshold
        ownScrollBars     : options.ownScrollBars

    if options.wrapper
      options.view = new KDView cssClass : "listview-wrapper"
    else
      options.view = listView

    super options, data

    listView.on 'ItemWasAdded', (view, index)=> @registerItem view, index
    listView.on 'ItemIsBeingDestroyed', (itemInfo)=> @unregisterItem itemInfo
    if options.keyNav
      listView.on 'KeyDownOnList', (event)=> @keyDownPerformed listView, event

  addDefaultItem:->
    {itemClass,options,data} = @getOptions().defaultItem
    @getListView().addSubView @defaultItem = new itemClass options, data

  removeDefaultItem:->
    @defaultItem.destroy() if @defaultItem

  putDefaultItem:(list=[])->
    if @getOptions().showDefaultItem
      if list.length is 0 then @addDefaultItem()
      else @removeDefaultItem()

  loadView:(mainView)->

    options = @getOptions()
    if options.scrollView
      scrollView = @scrollView
      mainView.addSubView scrollView
      scrollView.addSubView @getListView()
      if options.startWithLazyLoader
        @showLazyLoader no
      scrollView.on 'LazyLoadThresholdReached', @showLazyLoader.bind @

    @instantiateListItems(@getData()?.items or [])

    @getSingleton("windowController").on "ReceivedMouseUpElsewhere", (event)=> @mouseUpHappened event

  instantiateListItems:(items)->
    newItems = for itemData in items
      @getListView().addItem itemData

    @putDefaultItem newItems

    @emit "AllItemsAddedToList"

    return newItems

  ###
  HELPERS
  ###

  itemForId:(id)->

    @itemsIndexed[id]

  getItemsOrdered:->

    @itemsOrdered

  getItemCount:->

    @itemsOrdered.length

  setListView:(listView)->

    @listView = listView

  getListView:->

    @listView

  forEachItemByIndex:(ids, callback)->
    [callback, ids] = [ids, callback]  unless callback
    ids = [ids]  unless Array.isArray ids
    ids.forEach (id)=>
      item = @itemsIndexed[id]
      callback item  if item?

  showNoItemWidget:->
    {noItemFoundWidget, noMoreItemFoundWidget} = @getOptions()
    if @itemsOrdered.length > 0
      @scrollView.addSubView noMoreItemFoundWidget if noMoreItemFoundWidget
    else
      @scrollView.addSubView noItemFoundWidget if noItemFoundWidget

  hideNoItemWidget:->
    {noItemFoundWidget, noMoreItemFoundWidget} = @getOptions()
    noItemFoundWidget.destroy()     if noItemFoundWidget
    noMoreItemFoundWidget.destroy() if noMoreItemFoundWidget

  ###
  ITEM OPERATIONS
  ###

  addItem:(itemData, index, animation)->

    @getListView().addItem itemData, index, animation
    @putDefaultItem @getListView().items

  removeItem:(itemInstance, itemData, index)->

    @getListView().removeItem itemInstance, itemData, index
    @putDefaultItem @getListView().items
    dataId = itemData.getId?()

  registerItem:(view, index)->

    options = @getOptions()

    if index?
      actualIndex = if @getOptions().lastToFirst then @getListView().items.length - index - 1 else index
      @itemsOrdered.splice(actualIndex, 0, view)
    else
      @itemsOrdered[if @getOptions().lastToFirst then 'unshift' else 'push'] view
    if view.getData()?
      @itemsIndexed[view.getItemDataId()] = view

    if options.selection
      view.on 'click', (event)=> @selectItem view, event

    if options.keyNav or options.multipleSelection
      view.on "mousedown", (event)=> @mouseDownHappenedOnItem view, event
      view.on "mouseenter", (event)=> @mouseEnterHappenedOnItem view, event

  unregisterItem:(itemInfo)->

    @emit "UnregisteringItem", itemInfo
    {index, view} = itemInfo
    actualIndex = if @getOptions().lastToFirst then @getListView().items.length - index - 1 else index
    @itemsOrdered.splice actualIndex, 1
    if view.getData()?
      delete @itemsIndexed[view.getItemDataId()]

  replaceAllItems:(items)->

    @removeAllItems()
    @instantiateListItems items

  removeAllItems:->

    {itemsOrdered}  = @
    @itemsOrdered.length = 0
    @itemsIndexed = {}

    listView = @getListView()
    listView.empty() if listView.items.length

    return itemsOrdered

  ###
  HANDLING MOUSE EVENTS
  ###

  mouseDownHappenedOnItem:(item, event)->
    @getSingleton("windowController").setKeyView @getListView() if @getOptions().keyNav

    @lastEvent = event
    unless item in @selectedItems
      @mouseDown = yes
      @mouseDownTempItem = item
      @mouseDownTimer = setTimeout =>
        @mouseDown = no
        @mouseDownTempItem = null
        @selectItem item, event
      , 300

    else
      @mouseDown = no
      @mouseDownTempItem = null

  mouseUpHappened:(event)->

    clearTimeout @mouseDownTimer
    @mouseDown = no
    @mouseDownTempItem = null

  mouseEnterHappenedOnItem:(item, event)->

    clearTimeout @mouseDownTimer
    if @mouseDown
      @deselectAllItems() unless event.metaKey or event.ctrlKey or event.shiftKey
      @selectItemsByRange @mouseDownTempItem,item
    else
      @emit "MouseEnterHappenedOnItem", item

  ###
  HANDLING KEY EVENTS
  ###

  keyDownPerformed:(mainView, event)->

    switch event.which
      when 40, 38
        @selectItemBelowOrAbove event
        @emit "KeyDownOnListHandled", @selectedItems

  ###
  ITEM SELECTION
  ###

  # bad naming because of backwards compatibility i didn't
  # change the method name during refactoring - Sinan 10 May 2012
  selectItem:(item, event = {})->

    return unless item?

    @lastEvent = event

    if not(@getOption("multipleSelection"))\
       and item.getOption("selectable")\
       and not(event.metaKey or event.ctrlKey or event.shiftKey)
      @deselectAllItems()

    if event.shiftKey and @selectedItems.length > 0
      @selectItemsByRange @selectedItems[0], item
    else
      unless item in @selectedItems
        @selectSingleItem item
      else
        @deselectSingleItem item

    return @selectedItems

  selectItemBelowOrAbove:(event)->

    direction         = if event.which is 40 then "down" else "up"
    addend            = if event.which is 40 then 1 else -1

    selectedIndex     = @itemsOrdered.indexOf @selectedItems[0]
    lastSelectedIndex = @itemsOrdered.indexOf @selectedItems[@selectedItems.length - 1]

    if @itemsOrdered[selectedIndex + addend]
      unless event.metaKey or event.ctrlKey or event.shiftKey
        # navigate normally if meta key is NOT pressed
        @selectItem @itemsOrdered[selectedIndex + addend]
      else
        # take extra actions if meta key is pressed
        if @selectedItems.indexOf(@itemsOrdered[lastSelectedIndex + addend]) isnt -1
          # to be deselected item is in @selectedItems
          if @itemsOrdered[lastSelectedIndex]
            @deselectSingleItem @itemsOrdered[lastSelectedIndex]
        else
          # to be deselected item is NOT in @selectedItems
          if @itemsOrdered[lastSelectedIndex + addend ]
            @selectSingleItem @itemsOrdered[lastSelectedIndex + addend ]

  selectNextItem:(item, event)->

    [item] = @selectedItems unless item
    selectedIndex = @itemsOrdered.indexOf item
    @selectItem @itemsOrdered[selectedIndex + 1]

  selectPrevItem:(item, event)->

    [item] = @selectedItems unless item
    selectedIndex = @itemsOrdered.indexOf item
    @selectItem @itemsOrdered[selectedIndex + -1]


  deselectAllItems:()->
    for selectedItem in @selectedItems
      selectedItem.removeHighlight()
      deselectedItems = @selectedItems.concat []
      @selectedItems = []
      @getListView().unsetClass "last-item-selected"
      @itemDeselectionPerformed deselectedItems

  deselectSingleItem:(item)->
    item.removeHighlight()
    @selectedItems.splice @selectedItems.indexOf(item), 1
    if item is @itemsOrdered[@itemsOrdered.length-1]
      @getListView().unsetClass "last-item-selected"
    @itemDeselectionPerformed [item]

  selectSingleItem:(item)->

    if item.getOption("selectable") and !(item in @selectedItems)
      item.highlight()
      @selectedItems.push item
      if item is @itemsOrdered[@itemsOrdered.length-1]
        @getListView().setClass "last-item-selected"
      @itemSelectionPerformed()

  selectAllItems:()->

    @selectSingleItem item for item in @itemsOrdered


  selectItemsByRange:(item1, item2)->

    indicesToBeSliced = [@itemsOrdered.indexOf(item1), @itemsOrdered.indexOf(item2)]
    indicesToBeSliced.sort (a, b)-> a - b
    itemsToBeSelected = @itemsOrdered.slice indicesToBeSliced[0], indicesToBeSliced[1] + 1
    @selectSingleItem item for item in itemsToBeSelected
    @itemSelectionPerformed()

  itemSelectionPerformed:->

    @emit "ItemSelectionPerformed", @, (event : @lastEvent, items : @selectedItems)

  itemDeselectionPerformed:(deselectedItems)->

    @emit "ItemDeselectionPerformed", @, (event : @lastEvent, items : deselectedItems)

  ###
  LAZY LOADER
  ###

  showLazyLoader:(emitWhenReached = yes)->

    unless @lazyLoader
      @scrollView.addSubView @lazyLoader = new KDCustomHTMLView cssClass : "lazy-loader", partial : "Loading..."
      @lazyLoader.addSubView @lazyLoader.canvas = new KDLoaderView
        size          :
          width       : 16
        loaderOptions :
          color       : "#5f5f5f"
          diameter    : 16
          density     : 60
          range       : 0.4
          speed       : 3
          FPS         : 24

      @lazyLoader.canvas.show()
      @emit 'LazyLoadThresholdReached'  if emitWhenReached

  hideLazyLoader:->
    if @lazyLoader
      @lazyLoader.canvas.hide()
      @lazyLoader.destroy()
      @lazyLoader = null
