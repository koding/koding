class KDListView extends KDView
  constructor:(options,data)->
    options = $.extend
      type    : "default"
      # keyNav  : yes
    ,options
    options.cssClass = if options.cssClass? then "kdlistview kdlistview-#{options.type} #{options.cssClass}" else "kdlistview kdlistview-#{options.type}"
    @listSorter = options.sorter ? null
    @listSorter.setDelegate @ if @listSorter
    @items = [] unless @items
    super options,data
    # @activateKeyNav() if options.keyNav
  
  empty:->
    for item,i in @items
      item.destroy() if item?
    @items = []
  
  itemClass:(options,data)->
    new (@getOptions().subItemClass ? KDListItemView) options, data
  
  keyDown:(event)->
    event.stopPropagation()
    event.preventDefault()
    @propagateEvent KDEventType : "KeyDownOnList", event
  
  _addItemHelper:(itemData, options)->
    {index, animation, viewOptions} = options
    viewOptions or= {}
    viewOptions.delegate = @
    
    itemInstance = @itemClass viewOptions, itemData
    @addItemView itemInstance, index, animation
    
    itemInstance
  
  addHiddenItem:(item, index, animation)->
    @_addItemHelper item, {
      viewOptions :
        isHidden  : yes
        cssClass  : 'hidden-item'
      index
      animation
    }

  addItem:(itemData, index, animation)->
    @_addItemHelper itemData, {index, animation}

  removeItem:(itemInstance,itemData,index)->
    
    if index
      @propagateEvent KDEventType: 'ItemIsBeingDestroyed', { view : @items[index], index : index }
      @items.splice index,1
      item.destroy()
      return
    else
      for item,i in @items
        if itemInstance and itemInstance is item or
           itemData and itemdData is item.getData()
          @propagateEvent KDEventType: 'ItemIsBeingDestroyed', { view : item, index : i }
          @items.splice i,1
          item.destroy()
          return

  addItemView:(itemInstance,index,animation)->
    @propagateEvent KDEventType: 'ItemWasAdded', { view: itemInstance, index }
    if index?
      actualIndex = if @getOptions().lastToFirst then @items.length - index - 1 else index
      @items.splice actualIndex, 0, itemInstance
      @appendItemAtIndex itemInstance, index, animation
    else
      @items[if @getOptions().lastToFirst then 'unshift' else 'push'] itemInstance
      @appendItem itemInstance
    itemInstance

  destroy:(animated = no,animationType = "slideUp",duration = 100)->
    for item in @items
      # log "destroying listitem", item
      item.destroy()
    super()
 
  appendItem:(itemInstance,animation)->

    itemInstance.setParent @
    scroll = @doIHaveToScroll()
    # @items.push itemInstance
    if animation?
      itemInstance.getDomElement().hide()
      @getDomElement()[if @getOptions().lastToFirst then 'prepend' else 'append'] itemInstance.getDomElement()
      itemInstance.getDomElement()[animation.type] animation.duration,()=>
        itemInstance.propagateEvent KDEventType: 'introEffectCompleted'
    else
      @getDomElement()[if @getOptions().lastToFirst then 'prepend' else 'append'] itemInstance.getDomElement()
    if scroll
      @scrollDown()
    if @parentIsInDom
      itemInstance.propagateEvent KDEventType: 'viewAppended'
    null
    
  scrollDown: ->

    clearTimeout @_scrollDownTimeout
    @_scrollDownTimeout = setTimeout =>
      scrollView    = @$().closest(".kdscrollview")
      slidingView   = scrollView.find '> .kdview'
    
      # scrollTop         = scrollView.scrollTop()
      slidingHeight     = slidingView.height()
      # scrollViewheight  = scrollView.height()
      # scrollDown        = slidingHeight - scrollViewheight - scrollTop
      scrollView.animate (scrollTop : slidingHeight), (duration: 200, queue: no)
    , 50
    
  doIHaveToScroll: ->

    scrollView = @$().closest(".kdscrollview")
    if @getOptions().autoScroll
      if scrollView.length and scrollView[0].scrollHeight <= scrollView.height()
        yes
      else
        @isScrollAtBottom()
    else
      no
        
  isScrollAtBottom: ->

    scrollView        = @$().closest(".kdscrollview")
    slidingView       = scrollView.find '> .kdview'
    
    scrollTop         = scrollView.scrollTop()
    slidingHeight     = slidingView.height()
    scrollViewheight  = scrollView.height()
    
    if slidingHeight - scrollViewheight is scrollTop
      return yes
    else
      return no
    
  appendItemAtIndex:(itemInstance,index,animation)->

    itemInstance.setParent @
    actualIndex = if @getOptions().lastToFirst then @items.length - index - 1 else index
    if animation?
      itemInstance.getDomElement().hide()
      @getDomElement()[if @getOptions().lastToFirst then 'append' else 'prepend'] itemInstance.getDomElement() if index is 0
      @items[actualIndex-1].getDomElement()[if @getOptions().lastToFirst then 'before' else 'after']  itemInstance.getDomElement() if index > 0
      itemInstance.getDomElement()[animation.type] animation.duration,()=>
        itemInstance.propagateEvent KDEventType: 'introEffectCompleted' 
        # itemInstance.handleEvent { type : "viewAppended"}
    else
      @getDomElement()[if @getOptions().lastToFirst then 'append' else 'prepend'] itemInstance.getDomElement() if index is 0
      @items[actualIndex-1].getDomElement()[if @getOptions().lastToFirst then 'before' else 'after']  itemInstance.getDomElement() if index > 0
      # @items[actualIndex].getDomElement()[if @getOptions().lastToFirst then 'after' else 'before']  itemInstance.getDomElement()
      # itemInstance.handleEvent { type : "viewAppended"}
    if @parentIsInDom
      itemInstance.propagateEvent KDEventType: 'viewAppended'
    null
