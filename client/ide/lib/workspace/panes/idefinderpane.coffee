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

    appManager = kd.getSingleton 'appManager'

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


  getOpenFolders: (filterRootFolder = yes) ->

    fc          = @finderController
    folderPaths = fc.treeController.getOpenFolders()

    return folderPaths  unless filterRootFolder

    machineNodePath = fc.getMachineNode(@mountedMachine.uid).getData().path
    return folderPaths.filter (path) -> path isnt machineNodePath


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

    @on 'MachineMountRequested', (machine) ->
      fc.mountMachine machine

    @on 'MachineUnmountRequested', (machine) ->
      fc.unmountMachine machine.uid


    fc.on 'RootFolderChanged', (path) => @emitChangeHappened 'RootFolderChanged', path
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
        uid    : @mountedMachine.uid

    return change


  handleChange: (change = {}) ->

    return  unless change.type is 'FileTreeInteraction'

    { context } = change
    return  unless context

    { action, path, uid } = context

    fc = @finderController
    tc = fc.treeController

    tc.dontEmitChangeEvent = yes
    fc.dontEmitChangeEvent = yes

    switch action
      when 'Expanded'           then fc.expandFolders  path
      when 'Collapsed'          then tc.collapseFolder tc.nodes[path]
      when 'RootFolderChanged'  then fc.updateMachineRoot uid, path


    tc.dontEmitChangeEvent = no
    fc.dontEmitChangeEvent = no
