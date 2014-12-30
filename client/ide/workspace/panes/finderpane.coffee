class IDE.FinderPane extends IDE.Pane

  constructor: (options = {}, data) ->

    super options, data

    appManager  = KD.getSingleton 'appManager'
    computeCtrl = KD.getSingleton 'computeController'
    ideApp      = appManager.getFrontApp()

    appManager.open 'Finder', (finderApp) =>
      fc = @finderController = finderApp.create
        addAppTitle          : no
        bindMachineEvents    : no
        treeItemClass        : IDE.FinderItem
        treeControllerClass  : IDE.FinderTreeController
        contextMenuClass     : IDE.FinderContextMenuController

      @addSubView fc.getView()
      @bindListeners()


  bindListeners: ->

    mgr = KD.getSingleton 'appManager'
    fc  = @finderController
    tc  = @finderController.treeController

    fc.on 'FileNeedsToBeOpened', (file) ->
      file.fetchContents (err, contents) ->
        mgr.tell 'IDE', 'openFile', file, contents
        KD.getSingleton('windowController').setKeyView null

    tc.on 'TerminalRequested', (machine) ->
      mgr.tell 'IDE', 'openMachineTerminal', machine

    tc.on 'FolderCollapsed', (path) =>
      @emit 'ChangeHappened', @getChangeObject 'Collapsed', path

    tc.on 'FolderExpanded', (path) =>
      @emit 'ChangeHappened', @getChangeObject 'Expanded', path

    @on 'MachineMountRequested', (machine, rootPath) ->
      fc.mountMachine machine, { mountPath: rootPath }

    @on 'MachineUnmountRequested', (machine) ->
      fc.unmountMachine machine.uid


  makeReadOnly: -> @finderController.setReadOnly yes


  makeEditable: -> @finderController.setReadOnly no


  getChangeObject: (action, path) ->

    change     =
      origin   : KD.nick()
      type     : 'FileTreeInteraction'
      context  :
        action : action
        path   : path

    return change
