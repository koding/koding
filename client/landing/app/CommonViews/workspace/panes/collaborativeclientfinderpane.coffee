class CollaborativeClientFinderPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "finder-pane nfinder file-container client-finder-pane"

    super options, data

    @container = new KDView
      cssClass : "client-finder-pane"
      partial  : "Fetching remote file tree"

    panel              = @getDelegate()
    workspace          = panel.getDelegate()
    {@sessionKey}      = @getOptions()
    @workspaceRef      = workspace.firepadRef.child @sessionKey

    log "i am a client fake file tree and my session key is #{@sessionKey}"

    @workspaceRef.on "value", (snapshot) =>
      files = snapshot.val()?.files
      return  unless files

      fileInstances = []

      for file in files
        fileInstance = FSHelper.createFileFromPath file.path, file.type
        fileInstance.vmName = file.vmName
        fileInstances.push fileInstance

      @fileTree = new CollaborativeClientTreeViewController
        workspaceRef: @workspaceRef
      , fileInstances

      view = @fileTree.getView()
      @container.updatePartial ""
      @container.addSubView view

  pistachio: ->
    """
      {{> @container}}
    """




class CollaborativeClientTreeViewController extends JTreeViewController

  constructor: (options = {}, data) ->

    options.nodeIdPath        = "path"
    options.nodeParentIdPath  = "parentPath"
    options.contextMenu       = no
    options.loadFilesOnInit   = yes
    options.useStorage        = yes
    options.treeItemClass     = NFinderItem

    super options, data

  dblClick: (nodeView, event) ->
    log "Client interacted with this", nodeView

    nodeData = nodeView.getData()
    @getOptions().workspaceRef.set "ClientWantsToInteractWithRemoteFileTree":
      path   : nodeData.path
      type   : nodeData.type
      vmName : nodeData.vmName