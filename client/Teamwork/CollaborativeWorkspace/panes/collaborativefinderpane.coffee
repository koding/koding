# TODO: Should implement non-collaborative finder
# TODO: Should extend this class from NonCollab one.

class CollaborativeFinderPane extends CollaborativePane

  constructor: (options = {}, data) ->

    options.cssClass = "finder-pane nfinder file-container"

    super options, data

    @finderController = new NFinderController
      nodeIdPath          : "path"
      nodeParentIdPath    : "parentPath"
      contextMenu         : yes
      useStorage          : no
      treeControllerClass : options.treeControllerClass or CollaborativeFinderTreeController
      treeItemClass       : options.treeItemClass       or NFinderItem

    @container?.destroy()
    @finder = @container = @finderController.getView()

    @workspaceRef.on "value", (snapshot) =>
      snapshot   = @workspace.reviveSnapshot snapshot
      clientData = snapshot?.ClientWantsToInteractWithRemoteFileTree
      if clientData
        path             = "[#{clientData.vmName}]#{clientData.path}"
        {treeController} = @finderController
        nodeView         = treeController.nodes[path]
        nodeView.user    = clientData.user

        treeController.openItem nodeView, clientData
        @finderController.treeController.syncInteraction()

    @finderController.on "FileTreeInteractionDone", (files) =>
      @syncContent files

    @finderController.on "OpenedAFile", (file, content) =>
      fileHandler = @getOption "handleFileOpen"
      return fileHandler file, content  if fileHandler

      editorPane = @panel.getPaneByName @getOptions().editor
      unless editorPane
        for pane in @panel.panes
          if pane instanceof CollaborativeEditorPane or pane instanceof CollaborativeTabbedEditorPane
            editorPane = pane

      return  warn "could not find an editor instance to set file content" unless editorPane

      editorPane.openFile file, content

    @finderController.reset()  unless @workspace.getOptions().playground

    @finderController.on "CannotOpenImageFiles", =>
      new KDNotificationView
        type      : "mini"
        title     : "You cannot open image files in #{@workspace.getOptions().name}"
        container : @workspace
        duration  : 4200

    @finderController.treeController.on "HistoryItemCreated", (historyItem) =>
      @workspace.addToHistory historyItem

    # TODO: fatihacet - ExportRequested and PreivewRequested events should be
    # listened somewhere else since they are Teamwork related events.
    @finderController.treeController.on "ExportRequested", (node) =>
      new TeamworkExportModal {}, node

    @finderController.treeController.on "PreviewRequested", (node) =>
      tabView   = @workspace.getActivePanel().getPaneByName "tabView"
      nickname  = KD.nick()
      [t, path] = node.getData().path.split "#{nickname}/Web/"
      publicUrl = "https://#{nickname}.kd.io/#{path}"
      tabView.createPreview null, null, publicUrl

  syncContent: (files) ->
    @workspaceRef.set { files }


class CollaborativeFinderTreeController extends NFinderTreeController

  addNodes: (nodes) ->
    super nodes
    @syncInteraction()

  openItem: (nodeView, clientData) ->
    nodeData = nodeView.getData()
    keyword  = "opened"
    user     = if clientData then clientData.requestedBy else KD.nick()
    {name, path, type} = nodeData

    if type is "folder"
      isExpanded = @nodes[nodeData.path].expanded
      keyword    = if isExpanded then "collapsed" else "expanded"

    @emit "HistoryItemCreated",
      message  : "#{user} #{keyword} #{nodeData.name}"
      data     : { name, path, type }
      by       : user

    super nodeView

  getSnapshot: ->
    snapshot = []

    for own path, node of @nodes
      nodeData = node.data

      snapshot.push
        path   : FSHelper.plainPath path
        type   : nodeData.type
        vmName : nodeData.vmName
        name   : nodeData.name

    return snapshot

  syncInteraction: ->
    @getDelegate().emit "FileTreeInteractionDone", @getSnapshot()

  toggleFolder: (nodeView, callback) ->
    super nodeView, @bound "syncInteraction"

  openFile: (nodeView) ->
    return unless nodeView

    file      = nodeView.getData()
    fileType  = FSItem.getFileType extension
    extension = FSHelper.getFileExtension file.path
    delegate  = @getDelegate()

    return delegate.emit "CannotOpenImageFiles"  if fileType is "image"

    file.fetchContents (err, contents) =>
      delegate.emit "OpenedAFile", file, contents
