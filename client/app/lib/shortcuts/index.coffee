Shortcuts      = require 'shortcuts'
defaults       = require './config'
events         = require 'events'
_              = require 'underscore'
kd             = require 'kd'
os             = require 'os'
globals        = require 'globals'
ShortcutsModal = require './views/modal'

STORAGE_VERSION = '1'
THROTTLE_WAIT   = 300

module.exports =

class ShortcutsController extends events.EventEmitter

  klass = this

  constructor: (opts={}) ->
    # manages keyboard shortcuts.
    #
    # wraps over a _shortcuts_ instance by default (if not passed explicitly
    # within opts.shortcuts), and makes sure we are listening and dispatching
    # correct keyboard events depending on an application's config.
    #
    # this also exposes convenience proxy methods to get or update the underlying
    # _keyconfig_ instance, and persist the state of key-bindings to the server.

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


  addEventListeners: ->

    { appManager, appStorageController } = kd.singletons

    @_store = appStorageController.storage 'Keyboard', STORAGE_VERSION

    # make sure we are not accessing storage until its ready.
    # this also updates kb bindings which are initially listening
    # for default combos.
    @_store.ready _.bind @handleStoreReady, this

    # add valid kb event listeners and invalidate obsolete upon
    # front application is set and ready
    appManager.on 'FrontAppChange',
      _.bind @handleFrontAppChange, this

    # save db whenever a shortcut is changed.
    # this should handled with some care to avoid exhausting
    # resources, since shortcuts emits all changes.
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
    # invalidates previous app's keyboard events and adds new
    # listeners for the current one

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
    # renders a kd.Modal immediately

    new ShortcutsModal {}, @shortcuts.config


  getJSON: (name, filterFn) ->
    # convenience method that returns a collection's json repr.
    # this method omits all binding entries that is not compatible
    # with the current os/keymap type.

    set = @shortcuts.get(name)?.chain()

    if set
      if filterFn then set = set.filter filterFn
      set.map (model) ->
        _.extend model.toJSON(), binding: klass.getPlatformBindings model
      .value()


  @bindingsGetterMethodName: _.memoize ->
    # returns either "getMacKeys" or "getWinKeys"
    # see: http://github.com/koding/keyconfig

    kmt = globals.keymapType
    return "get#{kmt.charAt(0).toUpperCase()}#{kmt.slice 1, 3}Keys"


  @getPlatformBindings: (model) ->
    # given a keyconfig model, returns its bindings for this platform

    return model[klass.bindingsGetterMethodName()]()


  @getPlatformStorageKey: _.memoize ->
    # returns either "bindings-win" or "bindings-mac"

    return "bindings-#{globals.keymapType}"
