class CollaborativeTabbedEditorPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @panel            = @getDelegate()
    @workspace        = @panel.getDelegate()
    @sessionKey       = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef     = @workspace.firepadRef.child @sessionKey
    @isJoinedASession = @getOptions().sessionKey
    @openedFiles      = []
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
        for key, data of val.tabs
          if data.path and @openedFiles.indexOf(data.path) is -1
            file = FSHelper.createFileFromPath data.path
            @createEditorInstance file, null, data.sessionKey

    @workspaceRef.onDisconnect().remove()  if @workspace.amIHost()

  createEditorTabs: ->
    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate          : @
      addPlusHandle     : no

    @tabView = new ApplicationTabView
      delegate                  : @
      sortable                  : no
      closeAppWhenAllTabsClosed : no
      tabHandleContainer        : @tabHandleContainer

    @tabView.on "PaneAdded", (pane) =>
      {tabHandle} = pane
      tabHandle.on "click", =>
        activeTab = @tabView.getActivePane()
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
      delegate : @getDelegate()
      sessionKey
      file
      content
    }

    pane.addSubView editor
    @tabView.addPane pane
    @activeTabIndex = @tabView.panes.length

    workspaceRefData =
      sessionKey : editor.sessionKey

    if file
      workspaceRefData.path = file.path
      @openedFiles.push file.path

    @workspaceRef.child("tabs").push workspaceRefData  unless sessionKey

    pane.on "KDTabPaneDestroy", =>
      @workspaceRef.once "value", (snapshot) =>
        {tabs} = snapshot.val()
        return unless tabs
        for key, value of tabs when value.sessionKey is editor.sessionKey
          fileName = FSHelper.getFileNameFromPath tabs[key].path
          delete tabs[key]
        @workspaceRef.set { tabs }
        @workspace.setHistory "$0 closed #{fileName}"

      @openedFiles.splice @openedFiles.indexOf(file.path), 1

    return yes # return something instead of workspaceRef.child

  openFile: CollaborativeTabbedEditorPane::createEditorInstance

  handlePaneResized: ->
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