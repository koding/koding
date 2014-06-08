class FinderPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

    appManager = KD.getSingleton 'appManager'

    appManager.open 'Finder', (finderApp) =>
      fc = @finderController = finderApp.create()
      @addSubView fc.getView()
      @bindListeners()
      fc.reset()

      fc.on 'FileNeedsToBeOpened', (file)=>
        file.fetchContents (err, contents) ->
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
