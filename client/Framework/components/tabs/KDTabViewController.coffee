class KDTabViewController extends KDScrollView
  constructor:(options,data)->
    @handles = []
    @panes = []
    @selectedIndex = []
    @tabConstructor = options.tabClass ? KDTabPaneView
    # @listenTo "KDTabHandleViewMousedown",@handleMouseDownDefaultAction
    super options,data
    @setTabHandleContainer options.tabHandleContainer ? null

    @listenWindowResize()

    @on "PaneRemoved", => @resizeTabHandles type : "PaneRemoved"
    @on "PaneAdded", (pane)=> @resizeTabHandles {type : "PaneAdded", pane}

    if options.tabNames?
      @on "viewAppended", @createPanes.bind @


  handleMouseDownDefaultAction:(clickedTabHandle,event)->
    for handle,index in @handles
      if clickedTabHandle is handle
        @handleClicked(index,event)

  # DEFAULT ACTIONS
  handleClicked:(index,event)=>
    pane = @getPaneByIndex index
    if $(event.target).hasClass "close-tab"
      @removePane pane
      return no
    @showPane pane

  # DEFINE CUSTOM or DEFAULT tabHandleContainer
  setTabHandleContainer:(aViewInstance)->
    if aViewInstance?
      @tabHandleContainer.destroy() if @tabHandleContainer?
      @tabHandleContainer = aViewInstance
    else
      @tabHandleContainer = new KDView
      @appendHandleContainer()
    @tabHandleContainer.setClass "kdtabhandlecontainer"
  getTabHandleContainer:()-> @tabHandleContainer

  # ADD/REMOVE PANES
  createPanes:(paneTitlesArray = @getOptions().tabNames)->
    for title in paneTitlesArray
      @addPane pane = new @tabConstructor title : title,null
      pane.setTitle title

  addPane:(paneInstance, shouldShow=yes)->
    if paneInstance instanceof KDTabPaneView
      @panes.push paneInstance
      tabHandleClass = @getOptions().tabHandleView ? KDTabHandleView
      @addHandle newTabHandle = new tabHandleClass
        pane    : paneInstance
        title   : paneInstance.options.name
        hidden  : paneInstance.options.hiddenHandle
        view    : paneInstance.options.tabHandleView
      paneInstance.tabHandle = newTabHandle
      @listenTo
        KDEventTypes : "click"
        listenedToInstance : newTabHandle
        callback : @handleMouseDownDefaultAction
      @appendPane paneInstance
      @showPane paneInstance  if shouldShow
      @emit "PaneAdded", paneInstance
      return paneInstance
    else
      warn "You can't add #{paneInstance.constructor.name if paneInstance?.constructor?.name?} as a pane, use KDTabPaneView instead."
      false

  removePane:(pane)->
    pane.emit "KDTabPaneDestroy"
    index = @getPaneIndex pane
    isActivePane = @getActivePane() is pane
    @panes.splice(index,1)
    pane.destroy()
    handle = @getHandleByIndex index
    @handles.splice(index,1)
    handle.destroy()
    if isActivePane
      newIndex = if @getPaneByIndex(index-1)? then index-1 else 0
      @showPane @getPaneByIndex(newIndex) if @getPaneByIndex(newIndex)?
    @emit "PaneRemoved"

  # ADD/REMOVE HANDLES
  addHandle:(handle)->
    if handle instanceof KDTabHandleView
      @handles.push handle
      @appendHandle handle
      handle.setClass "hidden" if handle.getOptions().hidden
      return handle
    else
      warn "You can't add #{handle.constructor.name if handle?.constructor?.name?} as a pane, use KDTabHandleView instead."

  removeHandle:()->

  #TRAVERSING PANES/HANDLES
  checkPaneExistenceById:(id)->
    result = false
    for pane in @panes
      result = true if pane.id is id
    result

  getPaneByName:(name)->
    #FIXME: if there is a space in tabname it doesnt work
    result = false
    for pane in @panes
      result = pane if pane.name is name
    result

  getPaneById:(id)->
    paneInstance = null
    for pane in @panes
      paneInstance = pane if pane.id is id
    paneInstance

  getActivePane:()->
    @activePane = undefined if @panes.length is 0
    for pane in @panes
      @activePane = pane if pane.active
    @activePane

  getPaneByIndex:(index)-> @panes[index]
  getHandleByIndex:(index)-> @handles[index]

  getPaneIndex:(aPane)->
    return unless aPane
    result = 0
    for pane,index in @panes
      result = index if pane is aPane
    result

  #NAVIGATING
  showPaneByIndex:(index)->
    @showPane @getPaneByIndex index

  showPaneByName:(name)->
    @showPane @getPaneByName name

  showNextPane:->
    activePane  = @getActivePane()
    activeIndex = @getPaneIndex activePane
    @showPane @getPaneByIndex activeIndex + 1

  showPreviousPane:->
    activePane  = @getActivePane()
    activeIndex = @getPaneIndex activePane
    @showPane @getPaneByIndex activeIndex - 1


  #MODIFY PANES/HANDLES
  setPaneTitle:(pane,title)->
    handle = @getHandleByPane pane
    handle.getDomElement().find("b").html title

  getHandleByPane: (pane) ->
    index   = @getPaneIndex pane
    handle  = @getHandleByIndex index

  hideCloseIcon:(pane)->
    index = @getPaneIndex pane
    handle = @getHandleByIndex index
    handle.getDomElement().addClass("hide-close-icon")

  resizeTabHandles:->
    return if @_tabHandleContainerHidden
    #
    # visibleHandles = []
    # visibleTotalSize = 0
    #
    # #FIX hardcoded values
    # containerSize = @tabHandleContainer.getWidth()
    # for handle in @handles
    #   unless handle.$().hasClass("hidden")
    #     visibleHandles.push handle
    #     visibleTotalSize += handle.getWidth()
    #
    # if containerSize-50 < visibleTotalSize
    #   for handle in visibleHandles
    #     handle.$().css width : ((containerSize-50)/visibleHandles.length) - 15,200
    # else if containerSize-50 > visibleHandles.length * 113
    #   for handle in visibleHandles
    #     handle.$().css width : 113,200
    # else
    #   for handle in visibleHandles
    #     handle.$().css width : ((containerSize-50)/visibleHandles.length) - 15

  _windowDidResize:(event)=> @resizeTabHandles event

