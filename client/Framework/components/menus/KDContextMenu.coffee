class KDContextMenu extends KDView
  constructor:(options,data)->
    options = options ? {}
    super options, data
    @setClass "kdcontextmenu"
    @windowController = @getSingleton "windowController"
    @windowController.setKeyView @ #keyboard navigation of context menu
    @windowController.addLayer @

    @on 'ReceivedClickElsewhere', =>
      @destroy()

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : @
      callback : (pubInst,event)=> @aClick(pubInst,event)
      

  childAppended:->
    @positionContextMenu()
    super

  aClick:(pubInst,event)->
    unless event is @getOptions().event #don't destroy when this context menu click gets propagated
      @destroy()

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

  keyDown:(event)->
    switch event.which
      when 27 #esc
        @windowController.setKeyView @getDelegate()
        @destroy()
      # when 37 then @goLeft()
      # when 38 then @goUp()
      # when 39 then @goRight()
      # when 40 then @goDown()
    no


#FIXME: Move the finder-specific stuff out of the general context menu
class KDContextMenuTreeViewController extends KDTreeViewController
  constructor:(options,data)->
    options.subItemClass ?= KDContextMenuTreeItem
    super options,data
  
  itemClass:(options,data)->
    switch data.type
      when 'divider'
        item = new KDContextMenuListItemSeparator options, data
      else
        item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
        item.registerListener KDEventTypes : ['click'], callback : @clickOnMenuItem, listener : @
        
    item
  
  clickOnMenuItem:(source,event)=>
    
    return if source.data?.disabled
    
    contextMenuDelegate = @getView().delegate #context menu tree view delegate (item clicked)
    if source.data.callback and "function" is typeof source.data.callback
      source.data.callback.call contextMenuDelegate, source, event
    else if source.data?.function?
      performMethodName   = "perform#{source.data.function.capitalize()}"
      contextMenuDelegate[performMethodName]? contextMenuDelegate #launch pre process function if itemView has it

    contextMenuDelegate.propagateEvent 
      KDEventType : 'ContextMenuFunction'
      globalEvent : yes
    , {
      functionName : source.data.function
      contextMenuDelegate
    }
    
  loadView:->
    super
    @listenTo 
      KDEventTypes : "keydown"
      listenedToInstance : @getView().parent
      callback : @keyDownOnParent
      
  keyDownOnParent:(pubInst,event)=>
    # switch event.which
    #   when 37 then @goLeft()
    #   when 38 then @goUp()
    #   when 39 then @goRight()
    #   when 40 then @goDown()
    #   when 13 then @select event

  _selectFirstItemIfNeeded:->
    @makeItemSelected @itemsOrdered[0] unless @selectedItems[0]
    
  select:(event)->
    @clickOnMenuItem @selectedItems[0], event

  goLeft:()->
    @_selectFirstItemIfNeeded()
    item = @selectedItems[0]

  goUp:()->
    @_selectFirstItemIfNeeded()
    currentOrderedIndex = @orderedIndex @selectedItems[0].getData().id
    @selectNextVisibleItem currentOrderedIndex,-1
    @getView().makeScrollIfNecessary @selectedItems[0]
    @goUp() if @selectedItems[0] instanceof KDContextMenuListItemSeparator

  goRight:()->
    @_selectFirstItemIfNeeded()
    item = @selectedItems[0]
    if item.$subTreeWrapper
      item.$subTreeWrapper.fadeIn 100,()=>
        @_activeParent = item
        item.setClass "selected"
        @_activeSubtree = item.$subTreeWrapper

        if /localhost/.test location.host
          new KDNotificationView
            type    : "tray"
            title   : "Refactor KDTreeView!!!"
            content : "There are a lot of Finder specific things in KDTreeView <br/> which makes it impossible to use it on other places like this.<br><br><i>Don't worry this notification only shows in localhost :)</i>"
            duration: 10000
        
  goDown:()->
    @_selectFirstItemIfNeeded()
    super
    # log  @selectedItem, @itemsOrdered
    @goDown() if @selectedItems[0] instanceof KDContextMenuListItemSeparator
    

class KDContextMenuTreeView extends KDTreeView
  constructor:(options,data)->
    options = options ? {} 
    options.cssClass = "kdcontextmenutreeview"
    super options,data
    @setHeight "auto"

  setDomElement:()->
    @domElement = $ "<div id = '#{@id}' class='kdview #{@getOptions().cssClass}'></div>"

class KDContextMenuTreeItem extends KDTreeItemView
  constructor:(options = {},data)->
    options = $.extend
      bind : "mouseenter mouseleave"
    ,options
    super options,data

  partial:(data)->
    
    "<div class='context-menu-item'><span class='icon'></span><a href='#'>#{data.title}</a> </div>"

  mouseEnter:(event)->
    ###
    THIS ONLY SUPPORTS ONE LEVEL SUBMENU
    IF YOU PLAN TO HAVE INFINITE SUBMENUS
    GO AHEAD AND FIX HERE
    ###
    tree = @getDelegate()
    if tree._activeParent?

      if @getData().parentId is tree._activeParent.getData().parentId
        tree._leaveTimeout = setTimeout ()=>
          tree._activeSubtree.hide() if tree._activeSubtree
          tree._activeSubtree = null
          tree._activeParent.unsetClass "selected" if tree._activeParent
          tree._activeParent = null
        ,50

      if @$subTreeWrapper is tree._activeSubtree or @getData().parentId is tree._activeParent.getData().id
        clearTimeout tree._leaveTimeout if tree._leaveTimeout

      
    if @$subTreeWrapper
      tree._enterTimeout = setTimeout ()=>
        mainHeight  = @getSingleton('mainView').getHeight()
        subHeight   = @$subTreeWrapper.height()
        top         = @$().offset().top
        relativeTop = @$().position().top

        if top + subHeight > mainHeight
          setTop = mainHeight - (top + subHeight)

          @$subTreeWrapper.css 
            top: relativeTop - setTop
        
        @$subTreeWrapper.fadeIn 100,()=>
          tree._activeParent = @
          @setClass "selected"
          tree._activeSubtree = @$subTreeWrapper
      ,300
  
  mouseLeave:(event)->
    tree = @getDelegate()
    clearTimeout tree._enterTimeout if tree._enterTimeout
      

class KDContextMenuSubMenuItem extends KDTreeItemView
  constructor:(options,data)->
    options = options ? {}
    super options,data

  partial:(data)->
    partial = $ "<div class='context-menu-item'>
          <span class='iconic'></span>
          <a href='/#/#{data.type}/add' class='add-new-item' title='Add new #{data.type}'>#{data.title}</a>
      </div>"

class KDContextMenuListItemSeparator extends KDTreeItemView
  constructor:(options,data)->
    super options,data
  
  partial:(data)->
    $ "<div class='context-menu-item-separator'></div>"