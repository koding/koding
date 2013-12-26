class FinderController extends KDController

  KD.registerAppClass this,
    name         : "Finder"
    background   : yes

  constructor:(options, data)->

    options.appInfo = name : "Finder"

    super options, data

  createFileFromPath:(rest...)-> FSHelper.createFileFromPath rest...

  create: (options = {}) ->
    options.useStorage       ?= yes
    options.addOrphansToRoot ?= no
    options.delegate         ?= this
    @controller = new NFinderController options

    @controller.getView().addSubView @getUploader()
    return @controller

  getUploader: ->
    @uploaderPlaceholder = new KDView
      domId       : "finder-dnduploader"
      cssClass    : "hidden"

    @uploaderPlaceholder.addSubView @uploader = new DNDUploader
      hoverDetect : no
      delegate    : this

    {treeController} = @controller
    treeController.on 'dragEnter', @bound "onDrag"
    treeController.on 'dragOver' , @bound "onDrag"

    @uploader
      .on "dragleave", =>
        @uploaderPlaceholder.hide()

      .on "drop", =>
        @uploaderPlaceholder.hide()

      .on 'uploadProgress', ({ file, percent }) ->
        filePath = "[#{file.vmName}]#{file.path}"
        treeController.nodes[filePath]?.showProgressView percent

      .on "uploadComplete", ({ parentPath }) =>
        @controller.expandFolders FSHelper.getPathHierarchy parentPath

      .on "cancel", =>
        @uploader.setPath()
        @uploaderPlaceholder.hide()

    return @uploaderPlaceholder

  onDrag: ->
    return  if @controller.treeController.internalDragging
    @uploaderPlaceholder.show()
    @uploader.unsetClass "hover"
