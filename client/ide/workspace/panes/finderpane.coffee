class IDE.FinderPane extends IDE.Pane

  constructor: (options = {}, data) ->

    super options, data

    appManager = KD.getSingleton 'appManager'

    appManager.open 'Finder', (finderApp) =>
      fc = @finderController = finderApp.create
        addAppTitle   : no
        treeItemClass : IDE.FinderItem

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
