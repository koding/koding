class CollaborativePanel extends Panel

  constructor: (options = {}, data) ->

    super options, data
CollaborativePanel::EditorPaneClass   = CollaborativeEditorPane
CollaborativePanel::TerminalPaneClass = TerminalPane
CollaborativePanel::VideoPaneClass    = VideoPane
CollaborativePanel::PreviewPaneClass  = PreviewPane