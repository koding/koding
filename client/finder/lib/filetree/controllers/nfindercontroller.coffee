kd                           = require 'kd'
KDViewController             = kd.ViewController
KDCustomScrollView           = kd.CustomScrollView

isGuest                      = require 'app/util/isGuest'
FSHelper                     = require 'app/util/fs/fshelper'
showError                    = require 'app/util/showError'

NFinderItem                  = require '../itemviews/nfinderitem'
NFinderTreeController        = require './nfindertreecontroller'
NFinderContextMenuController = require './nfindercontextmenucontroller'


module.exports = class NFinderController extends KDViewController

  constructor: (options = {}, data) ->

    options.view = new KDCustomScrollView
      cssClass   : 'nfinder file-container'
      bind       : 'dragenter dragover dragleave dragend drop'

    treeOptions  = {}
    treeOptions.treeItemClass     = options.treeItemClass     or= NFinderItem
    treeOptions.contextMenuClass  = options.contextMenuClass  or= NFinderContextMenuController
    treeOptions.nodeIdPath        = options.nodeIdPath        or= 'path'
    treeOptions.nodeParentIdPath  = options.nodeParentIdPath  or= 'parentPath'
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
    treeOptions.saveChanges       = options.saveChanges        ?= yes
    treeOptions.delegate          = this

    super options, data

    TreeControllerClass = options.treeControllerClass or NFinderTreeController
    @treeController     = new TreeControllerClass treeOptions, []

    { appStorageController } = kd.singletons
    @appStorage = appStorageController.storage 'Finder', '2.0'
    @watchers = {}

    if options.useStorage

      @treeController.on 'folder.expanded', (folder) =>
        @setRecentFolder folder.path  unless @_restoreInProgress

      @treeController.on 'folder.collapsed', ({ path }) =>
        @unsetRecentFolder path
        @stopWatching path

    @cleanup()

    if options.bindMachineEvents

      { computeController } = kd.singletons

      computeController.on 'MachineDestroyed', ({ machineId }) =>
        @unmountMachine machineId

      computeController.on 'MachineStopped', ({ machineId }) =>
        @unmountMachine machineId

      computeController.on 'MachineStarted', ({ machineId }) =>
        computeController.fetchMachine { _id: machineId }, (err, machine) =>
          @mountMachine machine  unless err


  loadView: (mainView) ->

    mainView.wrapper.addSubView @treeController.getView()

    if @getOption 'loadFilesOnInit' then do @reset


  reset: ->

    kd.singletons.computeController.ready =>

      if @getOption 'useStorage'
      then @appStorage.ready @bound 'loadMachines'
      else kd.utils.defer    @bound 'loadMachines'


  loadMachines: ->

    if machineToMount = @getOption 'machineToMount'
      return @mountMachine machineToMount


  mountMachine: (machine, options = {}) ->

    unless machine
      kd.warn '[Finder][mountMachine] Machine not provided!'
      return

    unless machine.isRunning()
      return kd.warn "[Finder][mountMachine] Machine '#{machine.getName()}'
                      was not ready, I skipped it."

    @setOption 'machineToMount', machine

    { uid } = machine
    mRoots  = (@appStorage.getValue 'machineRoots') or {}
    options.fetchContent ?= yes

    findMountPath = (callback) =>
      if path = mRoots[uid]
      then callback path
      else machine.ready =>
        path = machine.info.home
        @updateMachineRoot uid, path, -> callback path

    findMountPath (path) =>

      @machines.push machineItem = FSHelper.createFileInstance
        name           : path
        path           : "[#{uid}]#{path}"
        type           : 'machine'
        machine        : machine
        treeController : @treeController
        parentPath     : 0

      machineItem = @treeController.addNode machineItem

      @emit 'MachineMounted', machine, path

      if options.fetchContent and machineItem
        @_restoreInProgress = yes
        @treeController.expandFolder machineItem, (err) =>
          @treeController.selectNode machineItem
          kd.utils.defer =>
            if @getOptions().useStorage then @reloadPreviousState uid
        , yes


  mountMachines: (machines) ->

    do @cleanup
    for machine in machines
      @mountMachine machine


  unmountMachine: (uid) ->

    return  unless machineItem = @getMachineNode uid

    @stopWatching machineItem.data.path
    FSHelper.unregisterMachineFiles uid
    @treeController.removeNodeView machineItem
    @machines = @machines.filter (vmData) -> vmData isnt machineItem.data


  updateMachineRoot: (uid, path, callback) ->

    return kd.warn 'Machine uid and new path required!'  unless uid or path

    machineRoots = (@appStorage.getValue 'machineRoots') or {}
    machineRoots[uid] = path

    callback?()

    if @getOptions().useStorage
      @appStorage.setValue 'machineRoots', machineRoots

    { computeController } = kd.singletons

    computeController.fetchMachine { uid }, (err, machine) =>
      return showError err  if err

      if machineItem = @getMachineNode uid
        @unmountMachine uid  if machineItem.data.path isnt "[#{uid}]#{path}"

      @mountMachine machine


  hideDotFiles: (uid) ->

    return  unless uid
    @setNodesHidden uid, yes
    for own path, node of @treeController.nodes
      file = node.getData()
      if (file.machine.uid is uid) and file.isHidden()
        @stopWatching file.path
        @treeController.removeNodeView node


  showDotFiles: (uid) ->

    return  unless uid
    @setNodesHidden uid, no
    for own path, node of @treeController.nodes when node.getData().type is 'machine'
      return if node.getData().machine.uid is uid
        @treeController.collapseFolder node, =>
          @treeController.expandFolder node, => @reloadPreviousState uid
        , yes


  isNodesHiddenFor: (uid) ->

    return yes  if @getOption 'hideDotFiles'
    return (@appStorage.getValue('machinesDotFileChoices') or {})[uid]


  setNodesHidden: (uid, state) ->

    prefs = @appStorage.getValue('machinesDotFileChoices') or {}
    prefs[uid] = state
    @store 'machinesDotFileChoices', prefs


  getRecentFolders: ->

    recentFolders = @appStorage.getValue('recentFolders')
    recentFolders = []  unless Array.isArray recentFolders
    return recentFolders


  setRecentFolder: (folderPath, callback) ->

    return  if @_restoreInProgress

    recentFolders = @getRecentFolders()
    unless folderPath in recentFolders
      recentFolders.push folderPath
    recentFolders
      .sort (path) ->
        if path is folderPath then -1 else 0
      .sort (a, b) ->
        a.length - b.length

    @store 'recentFolders', recentFolders, callback


  unsetRecentFolder: (folderPath, callback) ->

    recentFolders = @getRecentFolders()
    recentFolders = recentFolders
      .filter (path) ->
        path.indexOf(folderPath) isnt 0
      .sort (path) ->
        if path is folderPath then -1 else 0
      .sort (a, b) ->
        a.length - b.length

    @store 'recentFolders', recentFolders, callback


  expandFolder: (folderPath, callback = kd.noop) ->

    return  unless folderPath
    for own path, node of @treeController.nodes
      return @treeController.expandFolder node, callback  if path is folderPath

    callback { message:"Folder not exists: #{folderPath}" }


  expandFolders: (paths, callback = kd.noop) ->

    if typeof paths is 'string'
      paths = FSHelper.getPathHierarchy paths

    paths.sort (a, b) ->
      a.length - b.length

    path = paths.shift()

    @expandFolder path, (err) =>
      @unsetRecentFolder path  if err
      if paths.length is 0
      then callback null, @treeController.nodes[path]
      else @expandFolders paths, callback


  reloadPreviousState: (uid) ->

    recentFolders = @getRecentFolders()

    if uid

      recentFolders = recentFolders.filter (folder) ->
        folder.indexOf("[#{uid}]") is 0

      if recentFolders.length is 0
        recentFolders = ["[#{uid}]/"]

    @_restoreInProgress = yes
    @expandFolders recentFolders, => kd.utils.defer =>
      @_restoreInProgress = no


  uploadTo: (path) ->

    { uploader, uploaderPlaceholder } = @getDelegate()
    uploader.setPath path
    uploaderPlaceholder.show()


  # Filetree helpers
  #
  getMachineNode: (uid) ->

    return null  unless uid

    for own path, machineItem of @treeController.nodes
      if machineItem.data?.type is 'machine'
        if machineItem.data.machine.uid is uid or \
           machineItem.data.machine._id is uid
          return machineItem


  setReadOnly: (state) -> @treeController.isReadOnly = state


  # FS Watcher helpers
  #
  registerWatcher: (path, stopWatching) ->

    @watchers[path] = { stop: stopWatching }


  stopAllWatchers: ->

    (watcher.stop() for own path, watcher of @watchers)
    @watchers = {}


  stopWatching: (pathToStop) ->

    for own path, watcher of @watchers  when (path.indexOf pathToStop) is 0
      watcher.stop()
      delete @watchers[path]


  # Basics
  #
  cleanup: ->

    @treeController.removeAllNodes()
    FSHelper.resetRegistry()
    @stopAllWatchers()
    @machines = []


  store: (key, value, callback) ->

    callback ?= kd.noop
    if @getOption('saveChanges') is no
      return callback null
    @appStorage.setValue key, value, callback
