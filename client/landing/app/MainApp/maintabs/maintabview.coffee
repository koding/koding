class MainTabView extends KDTabView

  lastOpenPaneIndex = null

  constructor:(options,data)->
    options.resizeTabHandles    = yes
    options.lastTabHandleMargin = 40
    options.sortable            = yes
    @visibleHandles             = []
    @totalSize                  = 0
    @paneViewIndex              = {}
    super options,data

    appManager = @getSingleton("appManager")

    appManager.on 'AppViewAddedToAppManager', (appController, appView, options)=>

      @showPaneByView options, appView

    appManager.on 'AppViewRemovedFromAppManager', (appController, appView, options)=>
      log "gelmii mi? removePaneByView"
      @removePaneByView options, appView


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

    @getSingleton("contentDisplayController").emit "ContentDisplaysShouldBeHidden"
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

  removePane: (pane) ->
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

  removePaneByView:(view)->
    # log view, @getPaneByView view
    return unless (pane = @getPaneByView view)
    @_removePane pane

  showPaneByView:(options, view)->
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

  createTabPane:(options = {}, mainView)->

    @removePaneByView mainView if mainView?

    cssClass              = @utils.slugify(options?.name?.toLowerCase()) or ""
    options.cssClass      = @utils.curryCssClass "content-area-pane", cssClass
    options.type        or= "content"
    options.class       or= KDView
    options.hiddenHandle ?= yes

    paneInstance = new MainTabPane options, mainView

    paneInstance.on "viewAppended", =>
      @applicationPaneReady paneInstance, mainView

    @addPane paneInstance
    @indexPaneByView paneInstance,mainView

    # paneInstance.on "KDObjectWillBeDestroyed", => log "go to hell"
    # mainView.on "KDObjectWillBeDestroyed", => log "go to hell x 2"

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
