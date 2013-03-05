class MainTabView extends KDTabView

  lastOpenPaneIndex = null

  constructor:(options,data)->
    options.resizeTabHandles    = yes
    options.lastTabHandleMargin = 40
    options.sortable            = yes
    @visibleHandles             = []
    @totalSize                  = 0
    super options,data

    appManager = @getSingleton("appManager")

    appManager.on 'AppManagerWantsToShowAnApp', (controller, view, options)=>

      if view.parent
        @showPane view.parent
      else
        @createTabPane options, view


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

    # FIXME: SY
    # if paneMainView.data?.constructor.name is 'FSFile'
    #   @getSingleton('mainController').emit "SelectedFileChanged", paneMainView

    @emit "MainTabPaneShown", pane

    return pane

  removePane: (pane) ->
    pane.emit "KDTabPaneDestroy"
    index        = @getPaneIndex pane
    isActivePane = @getActivePane() is pane
    @panes.splice(index,1)
    pane.destroy()
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

  createTabPane:(options = {}, mainView)->

    options.cssClass = @utils.curryCssClass "content-area-pane", options.cssClass
    options.class  or= KDView

    paneInstance = new MainTabPane options


    paneInstance.once "viewAppended", =>
      @applicationPaneReady paneInstance, mainView
      if options.appInfo?.title?
        paneInstance.setTitle options.appInfo.title

    @addPane paneInstance

    return paneInstance

  applicationPaneReady: (pane, mainView) ->
    if pane.getOption("behavior") is "application"
      mainView.setClass 'application-page'
    pane.setMainView mainView

  rearrangeVisibleHandlesArray:->
    @visibleHandles = []
    for handle in @handles
      unless handle.getOptions().hidden
        @visibleHandles.push handle
