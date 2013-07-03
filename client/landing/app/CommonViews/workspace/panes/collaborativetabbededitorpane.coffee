class CollaborativeTabbedEditorPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    log "i am a CollaborativeTabbedEditorPane"

    @panel         = @getDelegate()
    @workspace     = @panel.getDelegate()
    @sessionKey    = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef  = @workspace.firepadRef.child @sessionKey

    @createEditorTabs()
    @createEditorInstance()

  createEditorTabs: ->
    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate      : @
      addPlusHandle : no

    @tabView = new ApplicationTabView
      delegate           : @
      tabHandleContainer : @tabHandleContainer

  createEditorInstance: (file, content) ->
    pane   = new KDTabPaneView
      name : file?.name or "Untitled.txt"

    editor = new CollaborativeEditorPane {
      delegate : @getDelegate()
      file
      content
    }

    pane.addSubView editor
    @tabView.addPane pane

    pane.on "KDTabPaneDestroy", =>
      @workspaceRef.once "value", (snapshot) =>
        {tabs} = snapshot.val()
        return unless tabs
        delete tabs[key] for key, value of tabs when value.sessionKey is editor.sessionKey
        @workspaceRef.set "tabs": tabs

    if file
      @workspaceRef.child("tabs").push
        path       : file.path
        sessionKey : editor.sessionKey

  openFile: CollaborativeTabbedEditorPane::createEditorInstance

  pistachio: ->
    return """
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """