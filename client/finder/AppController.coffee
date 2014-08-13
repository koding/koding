class FinderController extends KDController

  KD.registerAppClass this,
    name         : "Finder"
    background   : yes

  constructor: (options, data) ->

    options.appInfo = name : "Finder"

    super options, data

  create: (options = {}) ->
    options.useStorage       ?= yes
    options.addOrphansToRoot ?= no
    options.addAppTitle      ?= yes
    options.delegate         ?= this

    @controller = new NFinderController options
    finderView  = @controller.getView()

    finderView.addSubView @getAppTitleView()  if options.addAppTitle
    finderView.addSubView @getUploader()
    # finderView.addSubView @getMountVMButton()

    return @controller

  getAppTitleView: ->
    return new KDCustomHTMLView
      cssClass : "app-header"
      partial  : "Ace Editor"

  getMountVMButton: ->
    return new KDButtonView
      title    : "Mount other VMs"
      icon     : yes
      cssClass : "finder-mountvm clean-gray"
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
      cssClass      : "modal-with-text mount-vm"
      title         : "Mount VMs"
      overlay       : yes

    vmListController = new KDListViewController
      view          : list = new KDListView
        itemClass   : VMListItem
        type        : "vmlist"

    {vmController} = KD.singletons


    list.on "VmStateChanged", (options)=>

      vmController.fetchVmInfo options.hostnameAlias, (err, info)=>
        return KD.showError err  if err
        if options.state
        then @controller.mountVm info
        else @controller.unmountVm info.hostnameAlias

    list.once 'viewAppended', =>

      vmListController.showLazyLoader()
      vmController.fetchVMs (err, vms)->
        vmListController.hideLazyLoader()
        return KD.showError err  if err
        vmListController.instantiateListItems vms

    modal.addSubView vmListController.getView()


class VMListItem extends KDListItemView

  constructor:(options = {}, data)->

    super options, data


  viewAppended:->

    @addSubView loader = new KDLoaderView showLoader : yes

    {hostnameAlias} = @getData()
    KD.singletons.vmController.info hostnameAlias, (err, name, info)=>
      loader.hide()
      return KD.showError err if err
      @addSubView vmLabel  = new KDLabelView title: hostnameAlias
      @addSubView vmSwitch = new KodingSwitch
        cssClass     : 'dark'
        defaultValue : info.state is "RUNNING"
        callback     : (state)=>
          @getDelegate().emit "VmStateChanged", {state, hostnameAlias}
