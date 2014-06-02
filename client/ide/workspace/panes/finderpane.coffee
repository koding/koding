class FinderPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

    @createFinderController()
    @bindListeners()

  createFinderController: ->
    finderApp         = new FinderController
    @finderController = finderApp.create()

    @addSubView @finderController.getView()
    @finderController.reset()

    # this is legacy, should be deleted when we open source koding finder
    @finderController.getView().subViews.first.destroy()

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

