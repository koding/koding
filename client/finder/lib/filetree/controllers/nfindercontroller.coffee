kd = require 'kd'
KDCustomScrollView = kd.CustomScrollView
KDViewController = kd.ViewController
showError = require 'app/util/showError'
nick = require 'app/util/nick'
isGuest = require 'app/util/isGuest'
Machine = require 'app/providers/machine'
FSHelper = require 'app/util/fs/fshelper'
NFinderContextMenuController = require './nfindercontextmenucontroller'
NFinderItem = require '../itemviews/nfinderitem'
NFinderTreeController = require './nfindertreecontroller'
NoMachinesFoundWidget = require '../itemviews/nomachinesfoundwidget'


module.exports = class NFinderController extends KDViewController

  constructor:(options = {}, data)->

    options.view = new KDCustomScrollView
      cssClass   : 'nfinder file-container'
      bind       : 'dragenter dragover dragleave dragend drop'

    treeOptions  = {}
    treeOptions.treeItemClass     = options.treeItemClass     or= NFinderItem
    treeOptions.contextMenuClass  = options.contextMenuClass  or= NFinderContextMenuController
    treeOptions.nodeIdPath        = options.nodeIdPath        or= "path"
    treeOptions.nodeParentIdPath  = options.nodeParentIdPath  or= "parentPath"
    treeOptions.dragdrop          = options.dragdrop           ?= yes
    treeOptions.foldersOnly       = options.foldersOnly        ?= no
    treeOptions.hideDotFiles      = options.hideDotFiles       ?= no
    treeOptions.multipleSelection = options.multipleSelection  ?= yes
    treeOptions.addOrphansToRoot  = options.addOrphansToRoot   ?= no
    treeOptions.putDepthInfo      = options.putDepthInfo       ?= yes
    treeOptions.contextMenu       = options.contextMenu        ?= yes
    treeOptions.maxRecentFolders  = options.maxRecentFolders  or= 10
    treeOptions.useStorage        = options.useStorage         ?= no
    treeOptions.loadFilesOnInit   = options.loadFilesOnInit    ?= no
    treeOptions.delegate          = this

    super options, data


    TreeControllerClass = options.treeControllerClass or NFinderTreeController
    @treeController     = new TreeControllerClass treeOptions, []

    {appStorageController} = kd.singletons
    @appStorage = appStorageController.storage 'Finder', '2.0'

    @watchers = {}

    if options.useStorage

      @appStorage.ready =>

        @treeController.on "file.opened", @bound 'setRecentFile'

        @treeController.on "folder.expanded", (folder)=>
          @setRecentFolder folder.path

        @treeController.on "folder.collapsed", ({path})=>
          @unsetRecentFolder path
          @stopWatching path


    @noMachineFoundWidget = new NoMachinesFoundWidget
    @cleanup()

    if options.bindMachineEvents

      { computeController } = kd.singletons

      computeController.on "MachineDestroyed", ({machineId})=>
        @unmountMachine machineId

      computeController.on "MachineStopped", ({machineId})=>
        @unmountMachine machineId

      computeController.on "MachineStarted", ({machineId})=>
        computeController.fetchMachine machineId, (err, machine)=>
          @mountMachine machine  unless err


  loadView: (mainView) ->

    mainView.wrapper.addSubView @treeController.getView()
    mainView.wrapper.addSubView @noMachineFoundWidget

    if @getOption 'loadFilesOnInit' then do @reset


  reset:->

    kd.singletons.computeController.ready =>

      if @getOption 'useStorage'
      then @appStorage.ready @bound 'loadMachines'
      else kd.utils.defer    @bound 'loadMachines'


  loadMachines:->

    if machineToMount = @getOption 'machineToMount'
      return @mountMachine machineToMount

    { computeController } = kd.singletons

    computeController.fetchMachines (err, machines)=>

      unless showError err
        if machines.length > 0
        then @mountMachines machines
        else @noMachineFoundWidget.show()


  mountMachine: (machine, options = {}) ->
    options.fetchContent ?= yes

    unless machine.status.state is Machine.State.Running
      return kd.warn "Machine '#{machine.getName()}' was not ready, I skipped it."

    { uid } = machine
    mRoots  = (@appStorage.getValue 'machineRoots') or {}
    path    = options.mountPath or mRoots[uid] or "/home/#{nick()}"

    if @getMachineNode uid
      return kd.warn "Machine #{machine.getName()} is already mounted!"

    @updateMountState uid, yes

    @machines.push FSHelper.createFileInstance
      name           : path
      path           : "[#{uid}]#{path}"
      type           : "machine"
      machine        : machine
      treeController : @treeController
      parentPath     : 0

    @noMachineFoundWidget.hide()

    machineItem = @treeController.addNode @machines.last

    if options.fetchContent and machineItem

      kd.utils.defer =>

        @treeController.expandFolder machineItem, (err)=>

          @treeController.selectNode machineItem

          kd.utils.defer =>
            if @getOptions().useStorage then @reloadPreviousState uid
        , yes


  mountMachines: (machines) ->

    do @cleanup
    for machine in machines
      @mountMachine machine


  unmountMachine: (uid)->

    machineItem = @getMachineNode uid
    return kd.warn 'No such Machine!'  unless machineItem

    @updateMountState uid, no
    @stopWatching machineItem.data.path
    FSHelper.unregisterMachineFiles uid
    @treeController.removeNodeView machineItem
    @machines = @machines.filter (vmData)-> vmData isnt machineItem.data

    if @machines.length is 0
      @noMachineFoundWidget.show()
      @emit 'EnvironmentsTabRequested'

  updateMachineRoot:(uid, path, callback)->

    return kd.warn 'Machine uid and new path required!'  unless uid or path

    @unmountMachine uid
    callback?()

    machineRoots = (@appStorage.getValue 'machineRoots') or {}
    machineRoots[uid] = path

    if @getOptions().useStorage
      @appStorage.setValue 'machineRoots', machineRoots

    { computeController } = kd.singletons

    computeController.fetchMachine uid, (err, machine)=>
      return showError err  if err
      @mountMachine machine    if machine?


  setRecentFile:({path})->

    recentFiles = @appStorage.getValue('recentFiles')
    recentFiles = []  unless Array.isArray recentFiles

    unless path in recentFiles
      if recentFiles.length is @treeController.getOptions().maxRecentFiles
        recentFiles.pop()
      recentFiles.unshift path

    @appStorage.setValue 'recentFiles', recentFiles.slice(0,10), =>
      @emit 'recentfiles.updated', recentFiles


  hideDotFiles:(uid)->

    return  unless uid
    @setNodesHidden uid, yes
    for own path, node of @treeController.nodes
      file = node.getData()
      if (file.machine.uid is uid) and file.isHidden()
        @stopWatching file.path
        @treeController.removeNodeView node


  showDotFiles:(uid)->

    return  unless uid
    @setNodesHidden uid, no
    for own path, node of @treeController.nodes when node.getData().type is 'machine'
      return if node.getData().machine.uid is uid
        @treeController.collapseFolder node, =>
          @treeController.expandFolder node, => @reloadPreviousState uid
        , yes


  isNodesHiddenFor:(uid)->

    return yes  if @getOption 'hideDotFiles'
    return (@appStorage.getValue('machinesDotFileChoices') or {})[uid]


  setNodesHidden:(uid, state)->

    prefs = @appStorage.getValue('machinesDotFileChoices') or {}
    prefs[uid] = state
    @appStorage.setValue 'machinesDotFileChoices', prefs


  getRecentFolders:->

    recentFolders = @appStorage.getValue('recentFolders')
    recentFolders = []  unless Array.isArray recentFolders
    return recentFolders


  setRecentFolder:(folderPath, callback)->

    recentFolders = @getRecentFolders()
    unless folderPath in recentFolders
      recentFolders.push folderPath
    recentFolders.sort (path)-> if path is folderPath then -1 else 0
    @appStorage.setValue 'recentFolders', recentFolders, callback


  unsetRecentFolder:(folderPath, callback)->

    recentFolders = @getRecentFolders()
    recentFolders = recentFolders.filter (path)->
      path.indexOf(folderPath) isnt 0
    recentFolders.sort (path)->
      if path is folderPath then -1 else 0
    @appStorage.setValue 'recentFolders', recentFolders, callback


  expandFolder:(folderPath, callback=kd.noop)->

    return  unless folderPath
    for own path, node of @treeController.nodes
      return @treeController.expandFolder node, callback  if path is folderPath
    callback {message:"Folder not exists: #{folderPath}"}


  expandFolders: (paths, callback=kd.noop)->

    if typeof paths is 'string'
      paths = FSHelper.getPathHierarchy paths
    path = paths.pop()
    @expandFolder path, (err)=>
      @unsetRecentFolder path  if err
      if paths.length is 0
      then callback null, @treeController.nodes[path]
      else @expandFolders paths, callback


  reloadPreviousState:(uid)->

    recentFolders = @getRecentFolders()
    if uid
      recentFolders = recentFolders.filter (folder)->
        folder.indexOf "[#{uid}]" is 0
      if recentFolders.length is 0
        recentFolders = ["[#{uid}]/"]
    @expandFolders recentFolders


  uploadTo: (path)->

    {uploader, uploaderPlaceholder} = @getDelegate()
    uploader.setPath path
    uploaderPlaceholder.show()


  # Filetree helpers
  #
  getMachineNode:(uid)->

    return null  unless uid

    for own path, machineItem of @treeController.nodes
      if machineItem.data?.type is 'machine'
        if machineItem.data.machine.uid is uid or \
           machineItem.data.machine._id is uid
          return machineItem


  setReadOnly: (state) -> @treeController.isReadOnly = state


  # Settings helpers
  #
  updateMountState:(uid, state)->

    return  if isGuest()

    machines = @appStorage.getValue("mountedMachines") or {}
    machines[uid] = state

    @appStorage.setValue "mountedMachines", machines


  # FS Watcher helpers
  #
  registerWatcher:(path, stopWatching)->

    @watchers[path] = stop: stopWatching


  stopAllWatchers:->

    (watcher.stop() for own path, watcher of @watchers)
    @watchers = {}


  stopWatching:(pathToStop)->

    for own path, watcher of @watchers  when (path.indexOf pathToStop) is 0
      watcher.stop()
      delete @watchers[path]


  # Basics
  #
  cleanup:->

    @treeController.removeAllNodes()
    FSHelper.resetRegistry()
    @stopAllWatchers()
    @machines = []

