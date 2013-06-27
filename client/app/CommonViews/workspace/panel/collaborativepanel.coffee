class CollaborativePanel extends Panel

  constructor: (options = {}, data) ->

    super options, data

    workspace      = @getDelegate()
    panesLength    = @getOptions().panes.length
    createadPanes  = []

    @on "NewPaneCreated", (pane) =>
      createadPanes.push pane

      if createadPanes.length is panesLength
        @getDelegate().emit "AllPanesAddedToPanel", @, createadPanes

    log "i've created new panes with these keys", @getOptions().sessionKeys

  createPane: (paneOptions, targetContainer) ->
    PaneClass              = @getPaneClass paneOptions.type
    paneOptions.delegate   = @
    paneOptions.sessionKey = @getOptions().sessionKeys[@panes.length]  if @getOptions().sessionKeys
    pane                   = new PaneClass paneOptions

    targetContainer.addSubView pane
    @panes.push pane
    @emit "NewPaneCreated", pane


CollaborativePanel::EditorPaneClass   = CollaborativeEditorPane
CollaborativePanel::TerminalPaneClass = CollaborativeTerminalPane
CollaborativePanel::VideoPaneClass    = VideoPane
CollaborativePanel::PreviewPaneClass  = PreviewPane