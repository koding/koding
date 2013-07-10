class CollaborativeTabbedEditorPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    log "i am a CollaborativeTabbedEditorPane"

    @panel            = @getDelegate()
    @workspace        = @panel.getDelegate()
    @sessionKey       = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef     = @workspace.firepadRef.child @sessionKey
    @isJoinedASession = @getOptions().sessionKey
    @openedFiles      = []
    @activeTabIndex   = 0

    log "joined an old session again, creating new tabbed editor" if @isJoinedASession

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

    @on "PaneResized", =>
      @setHeight @parent.getHeight()
      for pane in @tabView.panes
        {codeMirrorEditor} = pane.subViews[0]
        codeMirrorEditor.display.wrapper.style.height = "#{@parent.getHeight() - 22}px"
        codeMirrorEditor.refresh()

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
        newIndex = @tabView.getPaneIndex @tabView.getActivePane()
        return  if newIndex is @activeTabIndex

        @workspaceRef.child("ActiveTabIndex").set newIndex
        @activeTabIndex = newIndex

  createEditorInstance: (file, content, sessionKey) ->
    if file
      fileIndexInOpenedFiles = @openedFiles.indexOf(file.path)
      if fileIndexInOpenedFiles > -1
        log "same file detected, setting tab acive"
        return  @tabView.showPaneByIndex fileIndexInOpenedFiles
    else
      file = FSHelper.createFileFromPath "localfile:/untitled.js"

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
        delete tabs[key] for key, value of tabs when value.sessionKey is editor.sessionKey
        @workspaceRef.set { tabs }

      @openedFiles.splice @openedFiles.indexOf(file.path), 1

    return yes # return something instead of workspaceRef.child

  openFile: CollaborativeTabbedEditorPane::createEditorInstance

  pistachio: ->
    return """
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """