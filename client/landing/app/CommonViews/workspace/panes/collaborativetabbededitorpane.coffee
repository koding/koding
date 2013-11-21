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
      tabHandleContainer        : @tabHandleContainer

    @tabView.on "PaneDidShow", =>
      activeTab = @getActivePane()
      newIndex  = @tabView.getPaneIndex activeTab
      return  if newIndex is @activeTabIndex

      @indexRef.set newIndex
      @activeTabIndex = newIndex

  createEditorInstance: (file, content, sessionKey) ->
    if file
      fileIndexInOpenedFiles = @openedFiles.indexOf(file.path)
      if fileIndexInOpenedFiles > -1
        return  @tabView.showPaneByIndex fileIndexInOpenedFiles
    else
      file = FSHelper.createFileFromPath "localfile:/untitled.txt"

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

    if file
      workspaceRefData.path = file.path
      @openedFiles.push file.path

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

      @openedFiles.splice @openedFiles.indexOf(file.path), 1

    return yes # return something instead of workspaceRef.child

  openFile: CollaborativeTabbedEditorPane::createEditorInstance

  handlePaneResized: ->
    return unless @parent
    @tabView.setHeight @parent.getHeight() - 22
    for pane in @tabView.panes
      pane.subViews[0].codeMirrorEditor.refresh()

  viewAppended: ->
    super
    @emit "PaneResized"

  pistachio: ->
    """
      {{> @header}}
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """