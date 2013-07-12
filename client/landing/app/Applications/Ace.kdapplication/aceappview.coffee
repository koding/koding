class AceAppView extends JView
  constructor: (options = {}, data) ->

    super options, data

    @aceViews   = {}
    @timestamp  = Date.now()
    @appManager = KD.getSingleton "appManager"

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate: @

    @tabView = new ApplicationTabView
      delegate             : @
      tabHandleContainer   : @tabHandleContainer
      saveSession          : yes
      sessionName          : "AceTabHistory"

    @on "SessionDataCreated", (@sessionData) =>

    @on "UpdateSessionData", (openPanes, data) =>
      @sessionData = @createSessionData openPanes, data
      @tabView.emit "SaveSessionData", @sessionData

    @on "SessionItemClicked", (items) =>
      if items.length > 1
        @appManager.open "Ace", { forceNew: true }, (appController) =>
          appView = appController.getView()
          appView.openFile FSHelper.createFileFromPath file for file in items
      else
        @openFile FSHelper.createFileFromPath file for file in items

    @tabView.on "PaneDidShow", (pane) =>
      {ace} = pane.getOptions().aceView
      @_windowDidResize()
      ace.on "ace.ready", -> ace.focus()
      ace.focus()

      # TODO: fatihacet - should add tab handle tooltips here

      # unless pane.tabHandle.tooltipCreated
      #   {nickname} = KD.whoami().profile
      #   title      = ace.data.path.replace("/Users/#{nickname}/", "~/").replace "localfile:/", ""
      #   pane.tabHandle.setTooltip
      #     title     : title
      #     placement : "bottom"
      #     delayIn   : 800
      #   pane.tabHandle.tooltipCreated = yes

      # ace.on "AceDidSaveAs", (name, parentPath) =>
      #   update tooltip title here

    @bindAppMenuEvents()

    @listenWindowResize()

  _windowDidResize:->
    # 10px being the application page's padding
    @tabView.setHeight @getHeight() - @tabHandleContainer.getHeight() - 10

  createOpenRecentsMenu: (eventName, item, contextmenu, offset) ->
    items = @createSessionListItems()
    return unless Object.keys(items).length
    contextMenu = new JContextMenu
      cssClass    : "recent-files-menu"
      delegate    : @
      x           : offset.left - 400
      y           : offset.top  + 180
      menuWidth   : 250
      arrow       :
        placement : "right"
        margin    : -5
    , items

  createSessionData: (openPanes, data = {}) ->
    paths     = []
    recordKey = "#{@id}-#{@timestamp}"

    for pane in openPanes
      {path} = pane.getOptions().aceView.getData()
      paths.push path if path.indexOf("localfile") is -1

    data[recordKey] = paths

    latest = data.latestSessions or= []
    latest.push recordKey if latest.indexOf(recordKey) is -1
    if latest.length > 10
      shifted = latest.shift()
      delete data[shifted]

    return @sessionData = data

  createSessionListItems: ->
    items       = {}
    sessionData = @sessionData
    {nickname}  = KD.whoami().profile
    itemCount   = 0
    for sessionId in sessionData.latestSessions
      return items if itemCount > 14
      sessionItems = sessionData[sessionId]
      sessionItems.forEach (path, i) =>
        filePath = path.replace("/home/#{nickname}", "~")
        items[filePath] = callback: => @emit "SessionItemClicked", [path]
        itemCount++

    return items

  reopenLastSession: ->
    data   = @sessionData
    latest = data.latestSessions
    if latest?.length > 0
      @emit "SessionItemClicked", data[latest.first]
    else
      @getActiveAceView().ace.notify "No recent file.", "error"

  viewAppended:->
    super
    @utils.wait 100, => @addNewTab() if @tabView.panes.length is 0

  addNewTab: (file) ->
    file = file or FSHelper.createFileFromPath 'localfile:/Untitled.txt'
    aceView = new AceView {}, file
    aceView.on 'KDObjectWillBeDestroyed', => @removeOpenDocument aceView
    @aceViews[file.path] = aceView
    @setViewListeners aceView

    pane = new KDTabPaneView
      name    : file.name or 'Untitled.txt'
      aceView : aceView

    @tabView.addPane pane
    pane.addSubView aceView

  setViewListeners: (view) ->
    @setFileListeners view.getData()

  getActiveAceView: ->
    return @tabView.getActivePane().getOptions().aceView

  isFileOpen: (file) -> @aceViews[file.path]?

  openFile: (file, isAceAppOpen) ->
    if file and @isFileOpen file
      mainTabView = KD.getSingleton("mainView").mainTabView
      mainTabView.showPane @parent
      @tabView.showPane @aceViews[file.path].parent
    else
      @addNewTab file

  removeOpenDocument: (aceView) ->
    return unless aceView
    @clearFileRecords aceView

  setFileListeners: (file) ->
    view = @aceViews[file.path]
    file.on "fs.saveAs.finished", (newFile, oldFile)=>
      if @aceViews[oldFile.path]
        view = @aceViews[oldFile.path]
        @clearFileRecords view
        @aceViews[newFile.path] = view
        view.setData newFile
        view.parent.setTitle newFile.name
        view.ace.setData newFile
        @setFileListeners newFile
        view.ace.notify "New file is created!", "success"
        KD.getSingleton('mainController').emit "NewFileIsCreated", newFile
    file.on "fs.delete.finished", => @removeOpenDocument @aceViews[file.path]

  clearFileRecords: (view) ->
    file = view.getData()
    delete @aceViews[file.path]

  bindAppMenuEvents: ->
    @on "saveMenuItemClicked", => @getActiveAceView().ace.requestSave()

    @on "saveAsMenuItemClicked", => @getActiveAceView().ace.requestSaveAs()

    @on "compileAndRunMenuItemClicked", => @getActiveAceView().compileAndRun()

    @on "previewMenuItemClicked", => @getActiveAceView().preview()

    @on "recentsMenuItemClicked", (eventName, item, contextmenu, offset) =>
      @createOpenRecentsMenu eventName, item, contextmenu, offset

    @on "reopenMenuItemClicked", => @reopenLastSession()

    @on "findMenuItemClicked", => @getActiveAceView().ace.showFindReplaceView()

    @on "findAndReplaceMenuItemClicked", => @getActiveAceView().ace.showFindReplaceView yes

    @on "exitMenuItemClicked", => @appManager.quit @appManager.frontApp

  advancedSettingsMenuView: ->
    pane = @tabView.getActivePane()
    {aceView} = pane.getOptions()
    settingsView = new KDView
      cssClass: "editor-advanced-settings-menu"
    settingsView.addSubView new AceSettingsView
      delegate: aceView.ace

    return settingsView

  pistachio: ->
    """
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """
