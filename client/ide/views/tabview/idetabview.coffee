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
      "Editor"    :
        callback  : => @createEditor()
      "Terminal"  :
        callback  : => @createTerminal()
    }

  createEditor: ->
    file       = FSHelper.createFileFromPath "localfile://Untitled.txt"
    content    = "This is my localfile"
    editor     = new EditorPane { file, content }
    pane       = new KDTabPaneView
      closable : yes
      name     : file.name

    pane.addSubView editor
    @tabView.addPane pane

  createTerminal: ->
    pane       = new KDTabPaneView
      closable : yes
      name     : "Terminal"

    pane.addSubView new TerminalPane
    @tabView.addPane pane
