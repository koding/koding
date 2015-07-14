kd = require 'kd'
KDController = kd.Controller
KDCustomHTMLView = kd.CustomHTMLView
KDView = kd.View
NFinderController = require './filetree/controllers/nfindercontroller'
DNDUploader = require 'app/commonviews/dnduploader'


module.exports = class FinderController extends KDController

  @options =
    name         : 'Finder'
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
      cssClass : "app-header"
      partial  : "Ace Editor"


  createUploader: (controller) ->

    uploaderPlaceholder = new KDView
      domId       : 'finder-dnduploader'
      cssClass    : 'hidden'

    uploaderPlaceholder.addSubView uploader = new DNDUploader
      hoverDetect : no
      delegate    : controller

    onDrag = (args...) =>

      { internalDragging }  = controller.treeController
      mouseEvent            = args.filter (arg) -> arg instanceof KDView is no

      if mouseEvent.length
        { items }  = mouseEvent[0].originalEvent.dataTransfer

        if items?[0].kind is 'string' and not internalDragging
          return finderView.overlay?.show()

      unless internalDragging
        uploaderPlaceholder.show()
        uploader.unsetClass 'hover'

    controller.on 'MachineMounted', (machine, path) ->

      uploader.setOption 'defaultPath', path
      uploader.reset()

    {treeController} = controller
    treeController.on 'dragEnter', onDrag
    treeController.on 'dragOver' , onDrag

    finderView = controller.getView()
    finderView.on 'dragenter', onDrag
    finderView.on 'dragover' , onDrag
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
