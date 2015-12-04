kd                             = require 'kd'
nick                           = require 'app/util/nick'
IDEPane                        = require './idepane'
showError                      = require 'app/util/showError'
IDEHelpers                     = require '../../idehelpers'
IDEFinderItem                  = require '../../finder/idefinderitem'
IDEFinderController            = require '../../finder/idefindercontroller'
IDEFinderTreeController        = require '../../finder/idefindertreecontroller'
IDEFinderContextMenuController = require '../../finder/idefindercontextmenucontroller'


module.exports = class IDEFinderPane extends IDEPane

  constructor: (options = {}, data) ->

    super options, data

    appManager  = kd.getSingleton 'appManager'
    computeCtrl = kd.getSingleton 'computeController'
    ideApp      = appManager.getFrontApp()

    appManager.open 'Finder', (finderApp) =>
      fc = @finderController = finderApp.create
        addAppTitle          : no
        bindMachineEvents    : no
        controllerClass      : IDEFinderController
        treeItemClass        : IDEFinderItem
        treeControllerClass  : IDEFinderTreeController
        contextMenuClass     : IDEFinderContextMenuController

      @addSubView fc.getView()
      @bindListeners()


  bindListeners: ->

    mgr = kd.getSingleton 'appManager'
    fc  = @finderController
    tc  = @finderController.treeController

    fc.on 'FileNeedsToBeOpened', (file) ->
      file.fetchContents (err, contents) ->
        if err
          console.error err
          return (IDEHelpers.showPermissionErrorOnOpeningFile err) or
            showError 'File could not be opened'

        mgr.tell 'IDE', 'openFile', { file, contents }
        kd.getSingleton('windowController').setKeyView null

    fc.on 'FileNeedsToBeTailed', (options) ->
      mgr.tell 'IDE', 'tailFile', options
      kd.getSingleton('windowController').setKeyView null


    tc.on 'TerminalRequested', (machine) ->
      mgr.tell 'IDE', 'openMachineTerminal', machine


    @on 'MachineMountRequested', (machine, rootPath) ->
      fc.mountMachine machine, { mountPath: rootPath }

    @on 'MachineUnmountRequested', (machine) ->
      fc.unmountMachine machine.uid

    @on 'DeleteWorkspaceFiles', (machineUId, rootPath) =>
      @finderController.treeController.deleteWorkspaceRootFolder machineUId, rootPath


    tc.on 'FolderCollapsed',   (path) => @emitChangeHappened 'Collapsed', path
    tc.on 'FolderExpanded',    (path) => @emitChangeHappened 'Expanded', path


  emitChangeHappened: (changeName, path) ->

    @emit 'ChangeHappened', @getChangeObject changeName, path


  makeReadOnly: -> @finderController.setReadOnly yes


  makeEditable: -> @finderController.setReadOnly no


  getChangeObject: (action, path) ->

    change     =
      origin   : nick()
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
