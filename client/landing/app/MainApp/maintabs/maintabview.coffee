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

    @on "PaneAdded", =>
      @tabHandleContainer.setWidth @getWidth()

    mainViewController = @getSingleton "mainViewController"
    mainViewController.on "UILayoutNeedsToChange", @bound "changeLayout"

  changeLayout:(options)->

    {hideTabs} = options

    if hideTabs
      @hideHandleContainer()
    else
      if @getSingleton('contentPanel').navOpenedOnce
        @showHandleContainer()


  # temp fix sinan 27 Nov 12
  # not calling @removePane but @_removePane
  handleClicked:(index, event)->
    pane        = @getPaneByIndex index
    appView     = pane.getMainView()
    appInstance = appManager.getByView appView
    options     = appInstance.getOptions()
    @getSingleton('router').handleRoute "#{options.route}"

    if $(event.target).hasClass "close-tab"
      pane.mainView.destroy()
      return no

    # this is a temporary fix for third party apps
    # until router handles everything correctly
    if options.route is '/Develop'
      appManager.showInstance appInstance

  showHandleContainer:->
    @tabHandleContainer.$().css top : -25
    @handlesHidden = no

  hideHandleContainer:->
    @tabHandleContainer.$().css top : 0
    @handlesHidden = yes

  showPane:(pane)->

    lastOpenPaneIndex = @getPaneIndex @getActivePane()

    # this is to hide stale static tabs
    @$("> .kdtabpaneview").removeClass "active"
    @$("> .kdtabpaneview").addClass "kdhiddentab"

    super pane

    # FIXME: SY
    # paneMainView = pane.getMainView()
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

    o = {}
    o.cssClass = @utils.curryCssClass "content-area-pane", options.cssClass
    o.class  or= KDView

    # this is a temporary hack
    # for reviving the main tabs
    # a better solution tbdl - SY

    domId           = "maintabpane-#{@utils.slugify options.name}"
    o.domId         = domId  if document.getElementById domId
    o.name          = options.name
    o.behavior      = options.behavior
    o.hiddenHandle  = options.hiddenHandle
    paneInstance    = new MainTabPane o

    paneInstance.once "viewAppended", =>
      @applicationPaneReady paneInstance, mainView
      appController = appManager.getByView mainView
      {appInfo}     = appController.getOptions()
      paneInstance.setTitle appInfo.title  if appInfo?.title

    @addPane paneInstance

    return paneInstance

  applicationPaneReady: (pane, mainView) ->
    if pane.getOption("behavior") is "application"
      mainView.setClass 'application-page'
    pane.setMainView mainView
    mainView.on "KDObjectWillBeDestroyed", =>
      @removePane pane

  rearrangeVisibleHandlesArray:->
    @visibleHandles = []
    for handle in @handles
      unless handle.getOptions().hidden
        @visibleHandles.push handle
