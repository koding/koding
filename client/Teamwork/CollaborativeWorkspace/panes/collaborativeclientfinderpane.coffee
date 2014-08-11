class CollaborativeClientFinderPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "finder-pane nfinder file-container client-finder-pane"

    super options, data

    @container    = new KDView
      cssClass    : "client-finder-pane"

    panel         = @getDelegate()
    workspace     = panel.getDelegate()
    {@sessionKey} = @getOptions()
    @workspaceRef = workspace.firebaseRef.child @sessionKey

    @createLoader()

    @workspaceRef.on "value", (snapshot) =>
      files = workspace.reviveSnapshot(snapshot)?.files
      return  unless files

      fileInstances = []

      # FIXME ACET
      for file in files
        fileInstance = FSHelper.createFileInstance
          path : file.path
          type : file.type

        fileInstance.vmName = file.vmName
        fileInstances.push fileInstance

      @fileTree = new CollaborativeClientTreeViewController { @workspaceRef, workspace }, fileInstances

      view = @fileTree.getView()
      @container.updatePartial ""
      @container.addSubView view

  createLoader: ->
    @container.addSubView loaderContainer = new KDView
      cssClass    : "loader-container"

    loaderContainer.addSubView new KDLoaderView
      showLoader  : yes
      size        :
        width     : 32

    loaderContainer.addSubView new KDCustomHTMLView
      tagName     : "p"
      partial     : "Fetching host's file tree"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """


class CollaborativeClientTreeViewController extends JTreeViewController

  constructor: (options = {}, data) ->

    options.nodeIdPath        = "path"
    options.nodeParentIdPath  = "parentPath"
    options.contextMenu       = no
    options.loadFilesOnInit   = yes
    options.treeItemClass     = NFinderItem

    super options, data

  dblClick: (nodeView, event) ->
    nodeData = nodeView.getData()
    @getOptions().workspaceRef.set "ClientWantsToInteractWithRemoteFileTree":
      path        : nodeData.path
      type        : nodeData.type
      vmName      : nodeData.vmName
      requestedBy : KD.nick()
