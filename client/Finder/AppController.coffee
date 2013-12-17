class FinderController extends KDController

  KD.registerAppClass this,
    name         : "Finder"
    background   : yes

  constructor:(options, data)->

    options.appInfo = name : "Finder"

    super options, data

  createFileFromPath:(rest...)-> FSHelper.createFileFromPath rest...

  create:(options = {})->

    options.useStorage       ?= yes
    options.addOrphansToRoot ?= no

    @controller = new NFinderController options

    @uploader = @createDNDUploader @controller

    return @controller

  createDNDUploader: (controller) ->

    { treeController } = controller

    dndUploadHolder = new KDView
      domId       : "finder-dnduploader"
      cssClass    : "hidden"

    dnduploader  = new DNDUploader
      hoverDetect : no

    dndUploadHolder.addSubView dnduploader

    onDrag = ->
      unless treeController.internalDragging
        dndUploadHolder.show()
        dnduploader.unsetClass "hover"

    dnduploader
      .on "dragleave", ->
        dndUploadHolder.hide()

      .on "drop", ->
        dndUploadHolder.hide()

      .on 'uploadProgress', ({ file, percent })->
        filePath = "[#{file.vmName}]#{file.path}"
        treeController.nodes[filePath]?.showProgressView percent

      .on "uploadComplete", ({ parentPath }) ->
        controller.expandFolders FSHelper.getPathHierarchy parentPath

      .on "cancel", ->
        dnduploader.setPath()
        dndUploadHolder.hide()

    treeController.on 'dragEnter',  onDrag
    treeController.on 'dragOver',   onDrag

    controller.getView().addSubView dndUploadHolder

    return dndUploadHolder

    # @finderController.treeController.on "dragEnter", onDrag
    # @finderController.treeController.on "dragOver",  onDrag

