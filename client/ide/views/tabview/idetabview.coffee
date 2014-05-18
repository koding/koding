 class IDETabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    super options, data

    @on "PlusHandleClicked", =>
      offset        = @holderView.plusHandle.$().offset()
      contextMenu   = new KDContextMenu
        delegate    : this
        x           : offset.left - 125
        y           : offset.top  + 30
        arrow       :
          placement : "top"
          margin    : -20
      , @getPlusMenuItems()

      contextMenu.once "ContextMenuItemReceivedClick", ->
        contextMenu.destroy()

  getPlusMenuItems: ->
    return {
      "Editor"       :
        callback     : => @createEditor()
      "Terminal"     :
        callback     : => @createTerminal()
      "Browser"      :
        callback     : => @createPreview()
      "Drawing Board":
        callback     : => @createDrawingBoard()
    }

  createEditor: ->
    file      = FSHelper.createFileFromPath "localfile://Untitled.txt"
    content   = "This is my localfile"
    editor    = new EditorPane { file, content, delegate: this }
    pane      = new KDTabPaneView
      name    : file.name
      aceView : editor.ace

    pane.addSubView editor
    @tabView.addPane pane

  createTerminal: ->
    pane   = new KDTabPaneView
      name : "Terminal"

    pane.addSubView new TerminalPane
    @tabView.addPane pane

  createDrawingBoard: ->
    pane   = new KDTabPaneView
      name : "Drawing"

    pane.addSubView new DrawingPane
    @tabView.addPane pane

  createPreview: ->
    pane   = new KDTabPaneView
      name : "Browser"

    pane.addSubView new PreviewPane
    @tabView.addPane pane

  removeOpenDocument: ->
    # TODO: This method is legacy, should be reimplemented in ace bundle.
