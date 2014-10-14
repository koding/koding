class FinderController extends KDController

  KD.registerAppClass this,
    name         : "Finder"
    background   : yes

  constructor: (options, data) ->

    options.appInfo = name : "Finder"

    super options, data

  create: (options = {}) ->
    options.useStorage        ?= yes
    options.addOrphansToRoot  ?= no
    options.addAppTitle       ?= yes
    options.bindMachineEvents ?= yes
    options.delegate          ?= this

    @controller = new NFinderController options
    finderView  = @controller.getView()

    finderView.addSubView @getAppTitleView()  if options.addAppTitle
    finderView.addSubView @getUploader()

    return @controller

  getAppTitleView: ->
    return new KDCustomHTMLView
      cssClass : "app-header"
      partial  : "Ace Editor"

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
