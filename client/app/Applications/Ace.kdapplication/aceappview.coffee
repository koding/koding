class AceAppView extends JView
  constructor: (options = {}, data) ->

    super options, data

    @aceViews       = {}

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate: @

    @tabView = new ApplicationTabView
      delegate           : @
      tabHandleContainer : @tabHandleContainer

    @on 'ViewClosed', => @emit 'AceAppViewWantsToClose'

    @on 'AllViewsClosed', => @emit 'AceAppViewWantsToClose'

    @tabView.on 'PaneDidShow', (pane) =>
      {ace} = pane.getOptions().aceView
      ace.on "ace.ready", -> ace.focus()
      ace.focus()

  viewAppended:->
    super
    
    @utils.defer =>
      @addNewTab() if @tabView.panes.length is 0

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

  isFileOpen: (file) -> @aceViews[file.path]?

  openFile: (file, isAceAppOpen) ->
    if file and @isFileOpen file
      mainTabView = @getSingleton("mainView").mainTabView
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
        @getSingleton('mainController').emit "NewFileIsCreated", newFile
    file.on "fs.delete.finished", => @removeOpenDocument @aceViews[file.path]

  clearFileRecords: (view) ->
    file = view.getData()
    delete @aceViews[file.path]

  pistachio: ->
    """
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """
