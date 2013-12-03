class CollaborativeTabbedEditorPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @openedFiles      = []
    @editors          = []
    @activeTabIndex   = 0
    @tabsRef          = @workspaceRef.child "tabs"
    @indexRef         = @workspaceRef.child "ActiveTabIndex"

    @createEditorTabs()
    @createEditorInstance()  unless @isJoinedASession

    @tabsRef.on "child_added", (snapshot) =>
      data = snapshot.val()
      return unless data

      if data.path and @openedFiles.indexOf(data.path) is -1
        file = FSHelper.createFileFromPath data.path
        @createEditorInstance file, null, data.sessionKey

    @tabsRef.on "child_removed", (snapshot) =>
      return  unless snapshot.val()
      basePath  = snapshot.val().path
      filePath  = if @amIHost then basePath else FSHelper.plainPath basePath
      fileIndex = @openedFiles.indexOf filePath
      fileTab   = @tabView.getPaneByIndex fileIndex

      return unless fileTab
      @tabView.removePane fileTab
      @workspaceRef.once "value", (snapshot) =>
        if snapshot.val()?.keys
          @indexRef.set @tabView.getPaneIndex @tabView.getActivePane()

    @indexRef.on "value", (snapshot) =>
      return if snapshot.val() is null
      @tabView.showPaneByIndex snapshot.val()

    @workspaceRef.onDisconnect().remove()  if @workspace.amIHost()

  getActivePaneEditor: ->
    return @editors[@getActivePaneIndex()] or null

  getActivePaneContent: ->
    return @getActivePaneEditor().getValue()

  getActivePaneFileData: ->
    return @getActivePaneEditor().getData()

  getActivePane: ->
    return @tabView.getActivePane()

  getActivePaneIndex: ->
    return @tabView.getPaneIndex @getActivePane()

  createEditorTabs: ->
    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate          : @
      addPlusHandle     : no

    @tabView = new ApplicationTabView
      delegate                  : @
      sortable                  : no
      closeAppWhenAllTabsClosed : no
      lastTabHandleMargin       : 200
      tabHandleContainer        : @tabHandleContainer

    @tabView.on "PaneDidShow", =>
      activeTab = @getActivePane()
      newIndex  = @tabView.getPaneIndex activeTab
      return  if newIndex is @activeTabIndex

      @indexRef.set newIndex
      @activeTabIndex = newIndex

  createEditorInstance: (file, content, sessionKey) ->
    file      = FSHelper.createFileFromPath "localfile:/untitled.txt"  unless file
    plainPath = FSHelper.plainPath file.path
    index     = @openedFiles.indexOf plainPath
    return @tabView.showPaneByIndex index  if index > -1

    pane   = new KDTabPaneView
      name : file.name

    editor = new CollaborativeEditorPane {
      delegate     : @getDelegate()
      saveCallback : @getOptions().saveCallback
      sessionKey
      file
      content
    }

    @forwardEvent editor, "EditorDidSave"
    @forwardEvent editor, "OpenedAFile"

    pane.addSubView editor
    @editors.push editor
    @tabView.addPane pane
    @activeTabIndex = @tabView.panes.length

    workspaceRefData =
      sessionKey : editor.sessionKey

    workspaceRefData.path = plainPath
    @openedFiles.push plainPath

    @tabsRef.push workspaceRefData  unless sessionKey

    pane.on "KDTabPaneDestroy", =>
      removedPaneIndex = @tabView.getPaneIndex pane
      @editors.splice removedPaneIndex, 1
      @workspaceRef.once "value", (snapshot) =>
        {tabs} = snapshot.val()
        return unless tabs
        for own key, value of tabs when value.sessionKey is editor.sessionKey
          fileName = FSHelper.getFileNameFromPath tabs[key].path
          delete tabs[key]
        @workspaceRef.set { tabs }

      @openedFiles.splice @openedFiles.indexOf(plainPath), 1

    return yes # return something instead of workspaceRef.child

  openFile: CollaborativeTabbedEditorPane::createEditorInstance

  viewAppended: ->
    super
    @emit "PaneResized"

  pistachio: ->
    """
      {{> @header}}
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """