class KDTabView extends KDScrollView

  constructor:(options = {}, data)->
    
    options.resizeTabHandles    ?= no
    options.maxHandleWidth      ?= 128
    options.minHandleWidth      ?= 30
    options.lastTabHandleMargin ?= 0
    options.sortable            ?= no
    @handles                     = []
    @panes                       = []
    @selectedIndex               = []
    @tabConstructor              = options.tabClass ? KDTabPaneView

    super options, data

    @setTabHandleContainer options.tabHandleContainer ? null

    @on "PaneRemoved", => @resizeTabHandles type : "PaneRemoved"
    @on "PaneAdded", (pane)=> @resizeTabHandles {type : "PaneAdded", pane}

    if options.tabNames?
      @on "viewAppended", @createPanes.bind @

    @setClass "kdtabview"

    @handlesHidden = no
    @resizeTimer   = null

    @hideHandleCloseIcons() if options.hideHandleCloseIcons
    @hideHandleContainer()  if options.hideHandleContainer

    @blockTabHandleResize = no

    @tabHandleContainer.on "mouseenter", => @blockTabHandleResize = yes

    @tabHandleContainer.on "mouseleave", => @blockTabHandleResize = no


  # ADD/REMOVE PANES
  createPanes:(paneTitlesArray = @getOptions().tabNames)->
    for title in paneTitlesArray
      @addPane pane = new @tabConstructor title : title,null
      pane.setTitle title

  addPane:(paneInstance)->
    if paneInstance instanceof KDTabPaneView
      @panes.push paneInstance
      tabHandleClass = @getOptions().tabHandleView ? KDTabHandleView
      @addHandle newTabHandle = new tabHandleClass
        pane      : paneInstance
        title     : paneInstance.options.name
        hidden    : paneInstance.options.hiddenHandle
        view      : paneInstance.options.tabHandleView
        sortable  : @getOptions().sortable

      paneInstance.tabHandle = newTabHandle
      @listenTo
        KDEventTypes : "click"
        listenedToInstance : newTabHandle
        callback : @handleMouseDownDefaultAction
      @appendPane paneInstance
      @showPane paneInstance
      @emit "PaneAdded", paneInstance

      newTabHandle.$().css maxWidth: @getOptions().maxHandleWidth

      newTabHandle.on "HandleIndexHasChanged", @bound "resortTabHandles"

      return paneInstance
    else
      warn "You can't add #{paneInstance.constructor.name if paneInstance?.constructor?.name?} as a pane, use KDTabPaneView instead."
      false

  resortTabHandles:->
    #   {subViews}       = @holder
    #   temp             = subViews[@draggedItemIndex]

    #   subViews.splice(@draggedItemIndex, 1);
    #   targetPos = if @isDraggingToLeft then Math.abs @passedHandleLength - @draggedItemIndex else @passedHandleLength + @draggedItemIndex
    #   subViews.splice(targetPos, 0, temp);

    #   names = ''
    #   names += ', ' + $(subView.domElement).find('b').text() for subView in subViews
    #   log names

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

  
  appendHandleContainer:()->
    @addSubView @tabHandleContainer

  appendPane:(pane)->
    pane.setDelegate @
    @addSubView pane

  appendHandle:(tabHandle)->
    @handleHeight or= @tabHandleContainer.getHeight()
    tabHandle.setDelegate @
    @tabHandleContainer.addSubView tabHandle
    # unless tabHandle.options.hidden
    #   tabHandle.$().css {marginTop : @handleHeight}
    #   tabHandle.$().animate({marginTop : 0},300) 

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

  
  #SHOW/HIDE ELEMENTS
  showPane:(pane)=>
    return unless pane
    @hideAllPanes()
    pane.show()
    index = @getPaneIndex pane
    handle = @getHandleByIndex index
    handle.makeActive()
    pane.emit "PaneDidShow"
    @emit "PaneDidShow", pane
    pane

  
  hideAllPanes:()->
    for pane in @panes
      pane.hide()
    for handle in @handles
      handle.makeInactive()

  showHandleContainer:()->
    @tabHandleContainer.show()
    @handlesHidden = no

  hideHandleContainer:()->
    @tabHandleContainer.hide()
    @handlesHidden = yes

  toggleHandleContainer:(duration = 0)-> @tabHandleContainer.$().toggle duration

  hideHandleCloseIcons:()->
    @tabHandleContainer.$().addClass "hide-close-icons"

  showHandleCloseIcons:()->
    @tabHandleContainer.$().removeClass "hide-close-icons"

  handleMouseDownDefaultAction:(clickedTabHandle,event)->
    for handle, index in @handles when clickedTabHandle is handle
      @handleClicked index, event      

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
      @tabHandleContainer = new KDView()
      @appendHandleContainer()
    @tabHandleContainer.setClass "kdtabhandlecontainer"
  getTabHandleContainer:()-> @tabHandleContainer

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
    index  = @getPaneIndex pane
    handle = @getHandleByIndex index

  hideCloseIcon:(pane)->
    index  = @getPaneIndex pane
    handle = @getHandleByIndex index
    handle.getDomElement().addClass "hide-close-icon"

  resizeTabHandles: KD.utils.throttle ->
    return if not @getOptions().resizeTabHandles or @_tabHandleContainerHidden or @blockTabHandleResize

    visibleHandles           = []
    visibleTotalSize         = 0
    options                  = @getOptions()
    containerSize            = @tabHandleContainer.$().outerWidth(no) - options.lastTabHandleMargin
    containerMarginInPercent = 100 * options.lastTabHandleMargin / containerSize

    for handle in @handles when not handle.isHidden()
      visibleHandles.push handle
      visibleTotalSize += handle.$().outerWidth no

    sizeWhenUsedMaxHandleWidth = visibleHandles.length * options.maxHandleWidth;
    possiblePercent = parseInt((100 - containerMarginInPercent) / visibleHandles.length, 10)

    handle.setWidth(possiblePercent, "%") for handle in visibleHandles
  , 300
