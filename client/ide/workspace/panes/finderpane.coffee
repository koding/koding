class IDE.FinderPane extends IDE.Pane

  constructor: (options = {}, data) ->

    super options, data

    appManager  = KD.getSingleton 'appManager'
    computeCtrl = KD.getSingleton 'computeController'
    ideApp      = appManager.getFrontApp()

    # TODO: 404 - Brain not found.
    # It should be fixed with computeController.ready but there is a race condition
    # there but I don't have enough brain to fix it right now.

    KD.utils.wait 2000, => # computeCtrl.ready =>
      for machine in computeCtrl.machines when machine.uid is ideApp.mountedMachineUId
        machineItem  = machine

      appManager.open 'Finder', (finderApp) =>
        fc = @finderController = finderApp.create
          addAppTitle   : no
          treeItemClass : IDE.FinderItem
          machineToMount: machineItem

        @addSubView fc.getView()
        @bindListeners()
        fc.reset()

  bindListeners: ->
    mgr = KD.getSingleton 'appManager'
    fc  = @finderController

    fc.on 'FileNeedsToBeOpened', (file) ->
      file.fetchContents (err, contents) ->
        mgr.tell 'IDE', 'openFile', file, contents
        KD.getSingleton('windowController').setKeyView null

    fc.treeController.on 'TerminalRequested', (machine) ->
      mgr.tell 'IDE', 'openVMTerminal', machine

    @on 'VMMountRequested',   (machine) -> fc.mountMachine machine

    @on 'VMUnmountRequested', (machine) -> fc.unmountMachine machine.uid
