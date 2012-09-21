class KDTreeView extends KDView
  constructor:->
    super
    @items = []

  destroy:(animated = no,animationType = "slideUp",duration = 100)->
    for item in @items
      # log "destroying treeitem", item
      item.destroy()
    super()

  setDomElement:()->
    options = @getOptions()
    type = if options?.type? then options.type else "default"
    cssClass = if options?.cssClass? then options.cssClass else ""
    @domElement = $ "<div class='kdtreeview kdtreeview-#{type} #{cssClass}'></div>"

  appendTreeItem:(treeItem)->
    @getDomElement().append treeItem.getDomElement()
    treeItem.parent = @
    treeItem.emit 'viewAppended'
    @items.push treeItem

  appendSubTreeItem:(treeItem,$subTreeWrapper)->
    $subTreeWrapper.append treeItem.getDomElement()
    treeItem.parent = @
    unless !!treeItem.isArchived
      treeItem.emit 'viewAppended'
    @items.push treeItem

  addSubView:(view, force)->
    warn "you can only add KDTreeItemView type as a list item to KDTreeView"
    if force
      super view

  addToSubTree:(parentItem, subItems)->
    parentItem.getDomElement().addClass "has-subitems"
    unless parentItem.$subTreeWrapper?
      parentItem.$subTreeWrapper = $ "<div class='sub-tree-wrapper'/>"
      parentItem.$subTreeWrapper.hide() unless (parentItem.getData().preExpanded ? no)
      parentItem.expanded = no # in the case of preexpanded, or new subtrees, @expandItem will set this later
      parentItem.$().after parentItem.$subTreeWrapper
    for item in subItems
      @appendSubTreeItem item, parentItem.$subTreeWrapper
    expandItem parentItem if parentItem.getData().preExpanded ? no


  createSubTrees:(newItems, controller)->
    for item in newItems
      if item.getData().items?
        item.getDomElement().addClass "has-subitems"
        unless item.$subTreeWrapper?
          item.$subTreeWrapper = $ "<div class='sub-tree-wrapper'/>"
          item.$subTreeWrapper.hide() unless (item.getData().preExpanded ? no)
          item.expanded = no # in the case of preexpanded, or new subtrees, @expandItem will set this later
        for own innerItemTitle,innerItem of item.getData().items
          @appendSubTreeItem instantiatedItem,item.$subTreeWrapper if (instantiatedItem = controller.itemForData innerItem)
        item.getDomElement().after item.$subTreeWrapper
        @expandItem item if item.getData().preExpanded ? no

  # createAndUnarchiveSubTrees:(newItems, controller)->
  #   for item in newItems
  #     unless !!item.isArchived
  #       if item.getData().items?
  #         item.getDomElement().addClass "has-subitems"
  #         unless item.$subTreeWrapper?
  #           item.$subTreeWrapper = $ "<div class='sub-tree-wrapper'/>"
  #           item.$subTreeWrapper.hide() unless (item.getData().preExpanded ? no)
  #           item.expanded = no # in the case of preexpanded, or new subtrees, @expandItem will set this later
  #         for own innerItemTitle,innerItem of item.getData().items
  #           @appendSubTreeItem instantiatedItem,item.$subTreeWrapper if (instantiatedItem = controller.itemForData innerItem)
  #         item.getDomElement().after item.$subTreeWrapper
  #         @expandItem item if item.getData().preExpanded ? no
  #     else
  #       unless item.$subTreeWrapper?
  #         item.$subTreeWrapper = $ "<div class='sub-tree-wrapper'/>"
  #         item.$subTreeWrapper.hide() unless item.expanded
  #       archivedItems = for own innerItemTitle, innerDataItem of item.getData().items
  #         if (archivedItem = controller.archivedItems[innerDataItem.path])?
  #           @appendSubTreeItem archivedItem,item.$subTreeWrapper
  #           archivedItem
  #       controller.putChildrenDataIntoParentNodes archivedItems,item.getData().items,item.getData().id,item.getData()
  #       @createAndUnarchiveSubTrees archivedItems, controller
  #       item.getDomElement().after item.$subTreeWrapper
  #       @expandItem item if item.expanded #FIXME: necessary?
  #

  removeSubTree:(parentItem, controller)->
    return unless parentItem.getData().items
    remove = (aParentItem)=>
      for own title, itemData of aParentItem.getData().items
        childItem = (controller.itemForData itemData) or controller.archivedItems[itemData.path]
        if childItem?
          remove childItem if childItem.getData()?.items?
          childItem.destroy()
      parentItem.getData().items = null
      parentItem.getDomElement().removeClass "has-subitems"
      parentItem.getDomElement().removeClass "expanded"
    remove parentItem
  #
  # archiveSubTree:(parentItem, controller)->
  #   return unless parentItem.getData().items
  #   archiveChildrenOf = (aParentItem)=>
  #     for own title, itemData of aParentItem.getData().items
  #       childItem = (controller.itemForData itemData) or controller.archivedItems[itemData.path]
  #       unless childItem?
  #         # itemData.destroy()
  #         continue
  #       archiveChildrenOf childItem if childItem.getData()?.items?
  #       childItem.isArchived = yes
  #       controller.archivedItems[itemData.path] = childItem
  #       childItem.getDomElement().detach() #detach leaves bindings
  #       childItem.$subTreeWrapper?.remove()
  #   archiveChildrenOf parentItem
  #
  #   if parentItem.$subTreeWrapper?[0] # HACK!!!!!!!!!!!! I didnt know what I can do more, this one deletes item which not more exist
  #     parentItem.$subTreeWrapper.html ''
  #
  #   parentItem.getData().items = null
  #   parentItem.getDomElement().removeClass "has-subitems"
  #   parentItem.getDomElement().removeClass "expanded"

  removeTreeItem:(item)->
    @removeSubTree item
    delete (itemData = item.getData()).parent?.items[itemData.title]
    item.destroy()

  expandOrCollapseItem:(publishingInstance)->
    if publishingInstance.expanded? and publishingInstance.expanded
      @collapseItem publishingInstance
    else
      @expandItem publishingInstance

  keyDown:(event)->
    # log "key down in tree view", event
    no

  expandItem:(item)->
    if item.$subTreeWrapper?
      # item.$subTreeWrapper.show()
      item.$subTreeWrapper.fadeIn 100
      # log @data
      # _.sortBy @data.items, (item) -> item.parentId
      # log @data
    item.expanded = yes
    item.getDomElement().addClass "expanded"
    @itemDidExpand item

  collapseItem:(item)->
    # log 'collapseItem', item
    item.expanded = false
    item.getDomElement().removeClass "expanded"
    # item.$subTreeWrapper.hide() if item.$subTreeWrapper?
    item.$subTreeWrapper.slideUp 70 if item.$subTreeWrapper?
    @itemDidCollapse item

  scrollDown: ->
    unless @__scrollDownInitiated
      @__scrollDownInitiated = yes
      scroll = @$().closest(".kdscrollview > div")
      start = scroll.scrollTop()
      @__scrollDownInterval = setInterval =>
        scroll.scrollTop start = start + 12
      , 40

  scrollUp: ->
    unless @__scrollUpInitiated
      @__scrollUpInitiated = yes
      scroll = @$().closest(".kdscrollview > div")
      start = scroll.scrollTop()
      @__scrollDownInterval = setInterval =>
        scroll.scrollTop start = start - 12
      , 40

  stopScroll: ->
    clearInterval @__scrollDownInterval
    @__scrollDownInitiated = no

    clearInterval @__scrollDownInterval
    @__scrollUpInitiated = no

  makeScrollIfNecessary:(firstSelectedItem)->
    $inner = @$()
    $outer = @$().parent()
    oHeight = $outer.height()
    oTopScroll = $outer.scrollTop()
    iHeight = $inner.height()
    itemTopOffset = firstSelectedItem.$().position().top
    anItemHeight = 24

    if iHeight > oHeight
      if itemTopOffset + anItemHeight > $outer.height()
        $outer.animate scrollTop : (oTopScroll + itemTopOffset - oHeight + anItemHeight), 0
      else if itemTopOffset < 0
        $outer.animate scrollTop : (oTopScroll + itemTopOffset), 0

  getChildren:(parentId)->
    # log parentId
    #log @data
    children = (child for child in @data.items when child.parentId is parentId)
    # log children

  makeItemDropTarget:(publishingInstance)->
    if publishingInstance instanceof KDTreeItemView
      $dropHelper = $ "<div/>"
        class   : "drop-helper"
      @removeAllDropHelpers()
      publishingInstance.getDomElement().prepend $dropHelper
    else
      warn "FIX: ",publishingInstance, "is not a KDTreeItemView, check event listeners!"

  removeAllDropHelpers:()->
    @getDomElement().find(".drop-helper").remove()


  # DELEGATE METHODS

  itemDidExpand:(item)->
    @propagateEvent KDEventType : 'ItemDidExpand', globalEvent : yes, item
    # log 'item did expand'

  itemDidCollapse:(item)->
    # log 'item did collapse',item





