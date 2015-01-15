FinderItem                  = require '../../finder/finderitem'
FinderTreeController        = require '../../finder/findertreecontroller'
FinderContextMenuController = require '../../finder/findercontextmenucontroller'
Pane                        = require './pane'


class FinderPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

    appManager  = KD.getSingleton 'appManager'
    computeCtrl = KD.getSingleton 'computeController'
    ideApp      = appManager.getFrontApp()

    appManager.open 'Finder', (finderApp) =>
      fc = @finderController = finderApp.create
        addAppTitle          : no
        bindMachineEvents    : no
        treeItemClass        : FinderItem
        treeControllerClass  : FinderTreeController
        contextMenuClass     : FinderContextMenuController

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


  handleChange: (change = {}) ->

    return  unless change.type is 'FileTreeInteraction'

    {context} = change
    return  unless context

    {action} = context
    fc = @finderController
    tc = fc.treeController

    tc.dontEmitChangeEvent = yes

    if      action is 'Expanded'  then fc.expandFolders context.path
    else if action is 'Collapsed' then tc.collapseFolder tc.nodes[context.path]

    tc.dontEmitChangeEvent = no


module.exports = FinderPane
