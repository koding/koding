class MainTabView extends KDTabView

  lastOpenPaneIndex = null

  constructor:(options,data)->
    options.resizeTabHandles = yes
    @visibleHandles   = []
    @totalSize        = 0
    @paneViewIndex    = {}
    super options,data

    @listenTo
      KDEventTypes : 'ApplicationWantsToBeShown'
      callback     :(app, {options, data})->
        @showPaneByView options, data

    @listenTo
      KDEventTypes : 'ApplicationWantsToClose'
      callback     :(app, {options, data})->
        @removePaneByView data

    @getSingleton("mainView").on "mainViewTransitionEnd", (e) =>
      if e.target is @getSingleton("contentPanel").domElement[0]
        @tabHandleContainer.setWidth @getWidth()
        @resizeTabHandles() 

  # temp fix sinan 27 Nov 12
  # not calling @removePane but @_removePane
  handleClicked:(index,event)->
    pane = @getPaneByIndex index
    if $(event.target).hasClass "close-tab"
      @removePane pane
      return no

    @showPane pane

  showHandleContainer:()->
    @tabHandleContainer.$().css top : -25
    @handlesHidden = no

  hideHandleContainer:()->
    @tabHandleContainer.$().css top : 0
    @handlesHidden = yes

  showPane:(pane)->

    lastOpenPaneIndex = @getPaneIndex @getActivePane()

    super pane

    paneMainView = pane.getMainView()

    if paneMainView.data?.constructor.name is 'FSFile'
      @getSingleton('mainController').emit "SelectedFileChanged", paneMainView

    paneMainView.handleEvent type : "click"
    @handleEvent {type : "MainTabPaneShown", pane}

    return pane

  _removePane: (pane) ->
    pane.handleEvent type : "KDTabPaneDestroy"
    index = @getPaneIndex pane
    isActivePane = @getActivePane() is pane
    @panes.splice(index,1)
    pane.destroy()
    @unindexPaneByView pane, pane.getData()
    handle = @getHandleByIndex index
    @handles.splice(index,1)
    handle.destroy()

    appPanes = []
    for pane in @panes
      appPanes.push pane if pane.options.type is "application"

    if isActivePane
      if @getPaneByIndex(lastOpenPaneIndex)?
        @showPane @getPaneByIndex(lastOpenPaneIndex)
      else if firstPane = @getPaneByIndex 0
        @showPane firstPane

    @emit "PaneRemoved"

    if appPanes.length is 0
      @emit "AllApplicationPanesClosed"


  removePane:(pane)->
    pane.getData().emit 'ViewClosed'
    # delete appManager.terminalIsOpen if pane.getData().$().hasClass('terminal-tab')

  removePaneByView:(view)->
    return unless (pane = @getPaneByView view)
    @_removePane pane

  showPaneByView:(options,view)->
    viewId = view
    pane = @getPaneByView view
    if pane?
      @showPane pane
    else
      @createTabPane options, view

  getPaneByView:(view)->
    if view then @paneViewIndex[view.id] else null

  indexPaneByView:(pane,view)->
    @paneViewIndex[view.id] = pane

  unindexPaneByView:(pane,view)->
    delete @paneViewIndex[view.id]

  createTabPane:(options,mainView)->
    @removePaneByView mainView if mainView?

    options = $.extend
      cssClass     : "content-area-pane #{__utils.slugify(options?.name?.toLowerCase()) or ""} content-area-new-tab-pane"
      hiddenHandle : yes
      type         : "content"
      class        : KDView
    ,options
    paneInstance = new MainTabPane options,mainView
    # log 'options', options
    paneInstance.on "viewAppended", =>
      # if options.controller  #dont need that anymore as tabHandle could be controlled by application
      #   options.controller.applicationPaneReady? mainView, paneInstance
      @applicationPaneReady paneInstance, mainView

    @addPane paneInstance
    @indexPaneByView paneInstance,mainView

    return paneInstance

  applicationPaneReady: (pane, mainView) ->
    # mainView.setDelegate pane
    mainView.setClass 'application-page' if pane.options.type is "application"
    pane.setMainView mainView

  tabPaneReady:(pane,event)->
    pageClass = KDView
    type = "content"
    if /^ace/.test pane.name
      pageClass = KD.getPageClass("Editor")
      type = "application"
    else if /^shell/.test pane.name
      pageClass = KD.getPageClass("Shell")
      type = "application"
    else
      pageClass = KD.getPageClass(pane.name) if KD.getPageClass(pane.name)

    pane.addSubView page = new pageClass
      delegate : pane
      cssClass : "#{type}-page"

  rearrangeVisibleHandlesArray:->
    @visibleHandles = []
    for handle in @handles
      unless handle.getOptions().hidden
        @visibleHandles.push handle
