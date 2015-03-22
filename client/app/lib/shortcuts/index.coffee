Shortcuts      = require 'shortcuts'
defaults       = require './config'
events         = require 'events'
_              = require 'underscore'
kd             = require 'kd'
os             = require 'os'
globals        = require 'globals'
ShortcutsModal = require './views/modal'

STORAGE_VERSION      = '1'
THROTTLE_WAIT        = 300

module.exports =

class ShortcutsController extends events.EventEmitter

  klass = this

  constructor: (opts={}) ->

    super()

    @_store        = null
    @_isStoreReady = no

    if opts.shortcuts instanceof Shortcuts
      @shortcuts = opts.shortcuts
    else
      raw = _.keys(defaults).reduce (acc, key) ->
        acc[key] = defaults[key].data
        return acc
      , {}
      @shortcuts = new Shortcuts raw


  getJSON: (name, filterFn) ->
    # convenience method that returns a collection's json repr.
    # this method omits all binding entries that is not compatible
    # with the current operating system

    set = @shortcuts.get(name)?.chain()

    if set
      if filterFn then set = set.filter filterFn
      set.map (model) ->
        _.extend model.toJSON(), binding: klass.getPlatformBindings model
      .value()


  addEventListeners: ->

    { appManager, appStorageController } = kd.singletons

    @_store = appStorageController.storage 'Keyboard', STORAGE_VERSION
    @_store.ready _.bind @handleStoreReady, this

    appManager.on 'FrontAppChange',
      _.bind @handleFrontAppChange, this

    @shortcuts.on 'change', (collection) =>
      @_save collection


  _save: _.throttle (collection) ->
    throw 'not ready'  unless @_isStoreReady

    data = collection.reduce (acc, model) ->
      acc[model.name] = klass.getPlatformBindings model
    , {}

    @_store.setValue klass.getPlatformStorageKey(), data

  , THROTTLE_WAIT,
    leading  : no
    trailing : yes


  _restore: ->
    throw 'not ready'  unless @_isStoreReady

    bindings = @_store.getValue(klass.getPlatformStorageKey()) or {}


  handleStoreReady: ->

    @_isStoreReady = yes

    @_restore()


  handleFrontAppChange: (app, prevApp) ->

    appId     = app.canonicalName
    prevAppId = prevApp?.canonicalName

    return  if appId is prevAppId

    if prevApp and _.isArray(sets = prevApp.getConfig().shortcuts)
      for key in sets
        @shortcuts.removeListener "key:#{key}", prevApp.bound 'handleShortcut'

    if _.isArray(sets = app.getConfig().shortcuts)
      for key in sets
        @shortcuts.on "key:#{key}", app.bound 'handleShortcut'


  showModal: ->

    new ShortcutsModal {}, @shortcuts.config


  @bindingsGetterMethodName: _.memoize ->

    kmt = globals.keymapType
    return "get#{kmt.charAt(0).toUpperCase()}#{kmt.slice 1, 3}Keys"


  @getPlatformBindings: (model) ->

    return model[klass.bindingsGetterMethodName()]()


  @getPlatformStorageKey: _.memoize ->

    return "bindings-#{globals.keymapType}"
