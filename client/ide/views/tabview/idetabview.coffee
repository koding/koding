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

  createPane_: (view, paneOptions) ->
    unless view or paneOptions
      return new Error "Missing argument for createPane_ helper"

    unless view instanceof KDView
      return new Error "View must be an instance of KDView"

    pane = new KDTabPaneView paneOptions
    pane.addSubView view
    @tabView.addPane pane

  createEditor: ->
    file      = FSHelper.createFileFromPath "localfile://Untitled.txt"
    content   = "This is my localfile"
    editor    = new EditorPane { file, content, delegate: this }
    paneOptions =
      name    : file.name
      aceView : editor.ace

    @createPane_ editor, paneOptions

  createTerminal: ->
    @createPane_ new TerminalPane, { name: "Terminal" }

  createDrawingBoard: ->
    @createPane_ new DrawingPane,  { name: "Drawing"  }

  createPreview: ->
    @createPane_ new PreviewPane,  { name: "Browser"  }

  removeOpenDocument: ->
    # TODO: This method is legacy, should be reimplemented in ace bundle.

  convertToSplitView: ->
    {parent} = this
    @detach()
    @unsetParent()

    newTabView = new IDETabView
    splitView  = new KDSplitView
      type     : "vertical" # TODO: Hardcoded, should be optional
      views    : [ this, newTabView ]

    parent.addSubView splitView
