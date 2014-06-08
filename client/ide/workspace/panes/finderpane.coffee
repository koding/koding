class FinderPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

    vmController = KD.getSingleton 'vmController'
    vmController.fetchDefaultVmName (vmName) =>
     @finder = new NFinderController
       nodeIdPath       : 'path'
       nodeParentIdPath : 'parentPath'
       contextMenu      : yes
       useStorage       : no

     @addSubView @finder.getView()
     @finder.updateVMRoot vmName, "/home/#{KD.nick()}"

     @finder.on 'FileNeedsToBeOpened', (file) =>
       file.fetchContents (err, contents) ->
         appManager = KD.getSingleton 'appManager'
         appManager.tell 'IDE', 'openFile', file, contents

  bindListeners: ->
    appManager = KD.getSingleton 'appManager'

    @finderController.on 'FileNeedsToBeOpened', (file) =>
      file.fetchContents (err, contents) ->
        appManager.tell 'IDE', 'openFile', file, contents

    @finderController.treeController.on 'TerminalRequested', (vm) =>
      appManager.tell 'IDE', 'openVMTerminal', vm

    @on 'VMMountRequested', (vm) =>
      @finderController.mountVm vm

    @on 'VMUnmountRequested', (vm) =>
      @finderController.unmountVm vm.hostnameAlias

