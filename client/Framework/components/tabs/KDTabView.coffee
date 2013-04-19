class KDTabView extends KDScrollView

  constructor:(options = {}, data)->

    options.resizeTabHandles     ?= no
    options.maxHandleWidth       ?= 128
    options.minHandleWidth       ?= 30
    options.lastTabHandleMargin  ?= 0
    options.sortable             ?= no
    options.hideHandleContainer  ?= no
    options.hideHandleCloseIcons ?= no
    @handles                      = []
    @panes                        = []
    @selectedIndex                = []
    @tabConstructor               = options.tabClass ? KDTabPaneView

    super options, data

    @activePane = null

    @setTabHandleContainer options.tabHandleContainer ? null

    @on "PaneRemoved", => @resizeTabHandles type : "PaneRemoved"
    @on "PaneAdded", (pane)=> @resizeTabHandles {type : "PaneAdded", pane}
    @on "PaneDidShow", @bound "setActivePane"
    if options.tabNames?
      @on "viewAppended", @createPanes.bind @

    @setClass "kdtabview"

    @handlesHidden = no

    @hideHandleCloseIcons() if options.hideHandleCloseIcons
    @hideHandleContainer()  if options.hideHandleContainer

    @blockTabHandleResize = no

    @tabHandleContainer.on "mouseenter", => @blockTabHandleResize = yes

    @tabHandleContainer.on "mouseleave", =>
      @blockTabHandleResize = no
      @resizeTabHandles()

  # ADD/REMOVE PANES
  createPanes:(paneTitlesArray = @getOptions().tabNames)->
    for title in paneTitlesArray
      @addPane pane = new @tabConstructor title : title,null
      pane.setTitle title

  addPane:(paneInstance, shouldShow=yes)->
    if paneInstance instanceof KDTabPaneView
      @panes.push paneInstance
      tabHandleClass = @getOptions().tabHandleView ? KDTabHandleView
      paneOptions    = paneInstance.options

      @addHandle newTabHandle = new tabHandleClass
        pane      : paneInstance
        title     : paneOptions.name or paneOptions.title
        hidden    : paneOptions.hiddenHandle
        view      : paneOptions.tabHandleView
        closable  : paneOptions.closable
        sortable  : @getOptions().sortable
        click     : (event)=> @handleMouseDownDefaultAction newTabHandle, event

      paneInstance.tabHandle = newTabHandle
      @appendPane paneInstance
      @showPane paneInstance  if shouldShow
      @emit "PaneAdded", paneInstance

      newTabHandle.$().css maxWidth: @getOptions().maxHandleWidth
      newTabHandle.on "HandleIndexHasChanged", @bound "resortTabHandles"

      return paneInstance
    else
      warn "You can't add #{paneInstance.constructor.name if paneInstance?.constructor?.name?} as a pane, use KDTabPaneView instead."
      false

  resortTabHandles: (index, dir) ->
    return if (index is 0 and dir is 'left') or (index is @handles.length - 1 and dir is 'right') or (index >= @handles.length) or (index < 0)

    @handles[0].unsetClass 'first'

    if dir is 'right'
      methodName  = 'insertAfter'
      targetIndex = index + 1
    else
      methodName  = 'insertBefore'
      targetIndex = index - 1
    @handles[index].$()[methodName] @handles[targetIndex].$()

    newIndex       = if dir is 'left' then index - 1 else index + 1
    splicedHandle  = @handles.splice index, 1
    splicedPane    = @panes.splice index, 1

    @handles.splice newIndex, 0, splicedHandle[0]
    @panes.splice   newIndex, 0, splicedPane[0]

    @handles[0].setClass 'first'

  removePane:(pane)->
    pane.emit "KDTabPaneDestroy"
    index = @getPaneIndex pane
    isActivePane = @getActivePane() is pane
    @panes.splice index, 1
    pane.destroy()
    handle = @getHandleByIndex index
    @handles.splice index, 1
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
  showPane:(pane)->
    return unless pane
    @hideAllPanes()
    pane.show()
    index  = @getPaneIndex pane
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

  hideHandleContainer:->
    @tabHandleContainer.hide()
    @handlesHidden = yes

  showHandleContainer:->
    @tabHandleContainer.show()
    @handlesHidden = no

  toggleHandleContainer:(duration = 0)->
    @tabHandleContainer.$().toggle duration

  hideHandleCloseIcons:()->
    @tabHandleContainer.$().addClass "hide-close-icons"

  showHandleCloseIcons:()->
    @tabHandleContainer.$().removeClass "hide-close-icons"

  handleMouseDownDefaultAction:(clickedTabHandle, event)->
    for handle, index in @handles when clickedTabHandle is handle
      @handleClicked index, event

  # DEFAULT ACTIONS
  handleClicked:(index,event)->
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

  getActivePane:-> @activePane

  setActivePane:(@activePane)->

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

    possiblePercent = ((100 - containerMarginInPercent) / visibleHandles.length).toFixed 2

    handle.setWidth(possiblePercent, "%") for handle in visibleHandles
  , 300
