kd = require 'kd'
KDController = kd.Controller
KDCustomHTMLView = kd.CustomHTMLView
KDView = kd.View
NFinderController = require './filetree/controllers/nfindercontroller'
DNDUploader = require 'app/commonviews/dnduploader'

require 'finder/styl'


module.exports = class FinderController extends KDController

  @options =
    name         : 'Finder'
    background   : yes


  constructor: (options, data) ->

    options.appInfo = { name : 'Finder' }

    super options, data


  create: (options = {}) ->

    options.useStorage        ?= yes
    options.addOrphansToRoot  ?= no
    options.addAppTitle       ?= yes
    options.bindMachineEvents ?= yes
    options.delegate          ?= this
    options.controllerClass  or= NFinderController

    controller = new options.controllerClass options
    finderView = controller.getView()

    finderView.addSubView @getAppTitleView()  if options.addAppTitle
    finderView.addSubView @createUploader controller

    finderView.putOverlay
      container   : finderView
      cssClass    : 'hidden'
      opacity     : 1
      transparent : yes

    { frontApp } = kd.singletons.appManager
    frontApp.on 'IDETabDropped', -> finderView.overlay?.hide()

    return controller


  getAppTitleView: ->

    new KDCustomHTMLView
      cssClass : 'app-header'
      partial  : 'Ace Editor'


  createUploader: (controller) ->

    uploaderPlaceholder = new KDView
      domId       : 'finder-dnduploader'
      cssClass    : 'hidden'

    uploaderPlaceholder.addSubView uploader = new DNDUploader
      hoverDetect : no
      delegate    : controller


    checkDraggingItem = (event) ->

      { dataTransfer } = event.originalEvent

      # Workaround for FF
      return yes  if dataTransfer.types?[0] is 'application/x-moz-file'

      # If the user isn't dragging a file and internalDragging is false, show the overlay.
      if dataTransfer.items?[0].kind isnt 'file' and not controller.treeController.internalDragging
        finderView.overlay?.show()
        return no

      return yes

    # Handle framework's drag events.
    onFwDrag = (nodeView, event) -> onDrag()  if checkDraggingItem event

    # Handle HTML's drag events.
    onNDrag = (event) -> onDrag()  if checkDraggingItem event

    onDrag = (event) ->

      unless controller.treeController.internalDragging
        uploaderPlaceholder.show()
        uploader.unsetClass 'hover'


    controller.on 'MachineMounted', (machine, path) ->

      uploader.setOption 'defaultPath', path
      uploader.reset()

    { treeController } = controller
    treeController.on 'dragEnter', onFwDrag
    treeController.on 'dragOver',  onFwDrag

    finderView = controller.getView()
    finderView.on 'dragenter', onNDrag
    finderView.on 'dragover',  onNDrag
    finderView.on 'drop', -> finderView.overlay?.hide()

    uploader
      .on 'dragleave', ->
        uploaderPlaceholder.hide()

      .on 'drop', ->
        uploaderPlaceholder.hide()

      .on 'uploadProgress', ({ file, progress }) ->
        filePath = "[#{file.machine.uid}]#{file.path}"
        treeController.nodes[filePath]?.showProgressView progress

      .on 'uploadComplete', ({ parentPath }) ->
        controller.expandFolders parentPath

      .on 'cancel', ->
        uploader.setPath()
        uploaderPlaceholder.hide()

    return uploaderPlaceholder
