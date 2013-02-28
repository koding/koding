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

    # fix this SY

    # if paneMainView.data?.constructor.name is 'FSFile'
    #   @getSingleton('mainController').emit "SelectedFileChanged", paneMainView

    # paneMainView.handleEvent type : "click"
    @handleEvent {type : "MainTabPaneShown", pane}

    return pane

  removePane: (pane) ->
    pane.handleEvent type : "KDTabPaneDestroy"
    index = @getPaneIndex pane
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

  # showPaneByName:(options, view)->
  #   {name} = options
  #   pane   = @getPaneByName name
  #   if pane
  #     super name
  #   else
  #     @createTabPane options, view

  createTabPane:(options = {}, mainView)->

    options.cssClass = @utils.curryCssClass "content-area-pane", options.cssClass
    options.class  or= KDView

    paneInstance = new MainTabPane options

    paneInstance.once "viewAppended", =>
      @applicationPaneReady paneInstance, mainView

    @addPane paneInstance

    return paneInstance

  applicationPaneReady: (pane, mainView) ->
    # mainView.setDelegate pane
    if pane.getOption("behavior") is "application"
      mainView.setClass 'application-page'
    pane.setMainView mainView

  # tabPaneReady:(pane,event)->
  #   pageClass = KDView
  #   type = "content"
  #   if /^ace/.test pane.name
  #     pageClass = KD.getPageClass("Editor")
  #     type = "application"
  #   else if /^shell/.test pane.name
  #     pageClass = KD.getPageClass("Shell")
  #     type = "application"
  #   else
  #     pageClass = KD.getPageClass(pane.name) if KD.getPageClass(pane.name)

  #   pane.addSubView page = new pageClass
  #     delegate : pane
  #     cssClass : "#{type}-page"

  rearrangeVisibleHandlesArray:->
    @visibleHandles = []
    for handle in @handles
      unless handle.getOptions().hidden
        @visibleHandles.push handle
