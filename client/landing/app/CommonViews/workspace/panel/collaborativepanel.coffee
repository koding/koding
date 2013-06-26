class CollaborativePanel extends Panel

  constructor: (options = {}, data) ->

    super options, data

    workspace = @getDelegate()

    @on "NewPaneCreated", (pane) =>
      log "NewPaneCreated", pane

CollaborativePanel::EditorPaneClass   = CollaborativeEditorPane
CollaborativePanel::TerminalPaneClass = TerminalPane
CollaborativePanel::VideoPaneClass    = VideoPane
CollaborativePanel::PreviewPaneClass  = PreviewPane