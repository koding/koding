class CollaborativeTabbedEditorPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @openedFiles      = []
    @editors          = []
    @activeTabIndex   = 0

    @createEditorTabs()
    @createEditorInstance()  unless @isJoinedASession

    @workspaceRef.on "value", (snapshot) =>
      val  = snapshot.val()
      return unless val

      if val.ActiveTabIndex?
        @tabView.showPaneByIndex val.ActiveTabIndex
        return @workspaceRef.child("ActiveTabIndex").remove()

      if val.tabs?
        for own key, data of val.tabs
          if data.path and @openedFiles.indexOf(data.path) is -1
            file = FSHelper.createFileFromPath data.path
            @createEditorInstance file, null, data.sessionKey

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

    @tabView.on "PaneAdded", (pane) =>
      {tabHandle} = pane
      tabHandle.on "click", =>
        activeTab = @getActivePane()
        newIndex  = @tabView.getPaneIndex activeTab
        return  if newIndex is @activeTabIndex

        @workspaceRef.child("ActiveTabIndex").set newIndex
        @activeTabIndex = newIndex
        @workspace.setHistory "$0 switched to #{activeTab.getOptions().name}"

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

    @forwardEvent editor, 'EditorDidSave'
    @forwardEvent editor, 'OpenedAFile'

    pane.addSubView editor
    @editors.push editor
    @tabView.addPane pane
    @activeTabIndex = @tabView.panes.length

    workspaceRefData =
      sessionKey : editor.sessionKey

    if file
      workspaceRefData.path = file.path
      @openedFiles.push file.path

    @workspaceRef.child("tabs").push workspaceRefData  unless sessionKey

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
        @workspace.setHistory "$0 closed #{fileName}"

      @openedFiles.splice @openedFiles.indexOf(file.path), 1

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