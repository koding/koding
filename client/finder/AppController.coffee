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
    @controller.getView().addSubView @getMountVMButton()
    return @controller

  getMountVMButton: ->
    @uploaderPlaceholder = new KDButtonView
      title    : "Mount others..."
      domId    : "finder-mountvm"
      callback : @bound 'showMountVMModal'

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

  showMountVMModal: ->
    modal = new KDModalView
      width         : 620
      cssClass      : "modal-with-text"
      title         : "Mount VM's"
      overlay       : yes
      buttons       :
        cancel      :
          title     : "Cancel"
          callback  : -> modal.destroy()

    vmListController = new KDListViewController
      view           : new KDListView
        itemClass    : VMListItem

    KD.singletons.vmController.fetchVMs (err, vms)->
      return KD.showError err if err
      vmListController.instantiateListItems vms
      modal.addSubView vmListController.getListView()

    vmListController.getListView().on "VmStateChanged", (options)=>
      KD.singletons.vmController.fetchVmInfo options.hostnameAlias, (err, info)=>
        return KD.showError err if err
        if options.state then @controller.mountVm info else \
        @controller.unmountVm info.hostnameAlias


