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

    controller = new NFinderController options
    finderView = controller.getView()

    finderView.addSubView @getAppTitleView()  if options.addAppTitle
    finderView.addSubView @createUploader controller

    return controller


  getAppTitleView: ->

    new KDCustomHTMLView
      cssClass : "app-header"
      partial  : "Ace Editor"


  createUploader: (controller)->

    uploaderPlaceholder = new KDView
      domId       : 'finder-dnduploader'
      cssClass    : 'hidden'

    uploaderPlaceholder.addSubView uploader = new DNDUploader
      hoverDetect : no
      delegate    : controller

    onDrag = ->

      unless controller.treeController.internalDragging
        uploaderPlaceholder.show()
        uploader.unsetClass 'hover'

    {treeController} = controller
    treeController.on 'dragEnter', onDrag
    treeController.on 'dragOver' , onDrag

    finderView = controller.getView()
    finderView.on 'dragenter', onDrag
    finderView.on 'dragover' , onDrag

    uploader
      .on 'dragleave', ->
        uploaderPlaceholder.hide()

      .on 'drop', ->
        uploaderPlaceholder.hide()

      .on 'uploadProgress', ({ file, percent }) ->
        filePath = "[#{file.machine.uid}]#{file.path}"
        treeController.nodes[filePath]?.showProgressView percent

      .on 'uploadComplete', ({ parentPath }) ->
        controller.expandFolders parentPath

      .on 'cancel', ->
        uploader.setPath()
        uploaderPlaceholder.hide()

    return uploaderPlaceholder
