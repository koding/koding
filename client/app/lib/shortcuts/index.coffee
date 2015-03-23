Shortcuts      = require 'shortcuts'
defaults       = require './config'
events         = require 'events'
_              = require 'underscore'
kd             = require 'kd'
globals        = require 'globals'
ShortcutsModal = require './views/modal'
cloneArray     = require 'app/util/cloneArray'

STORAGE_NAME    = 'shortcuts'
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

    @_store = null

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

    @_store = appStorageController.storage
      name    : klass.getPlatformStorageKey()
      version : STORAGE_VERSION
      fetch   : no

    # make sure we are not accessing storage until its ready.
    # this also updates kb bindings which are initially listening
    # for default combos.
    @_store.once 'ready', _.bind @_handleStoreReady, this

    # add valid kb event listeners and invalidate obsolete upon
    # front application is set and ready
    appManager.on 'FrontAppChange', _.bind @_handleFrontAppChange, this

    @_store.fetchStorage null, yes


  _save: _.throttle (collection, model) ->

    throw 'could not persist changes'  unless @_store.isReady
    # also means: do not call this method explicitly, use #update

    throw 'not implemented :trollface:'

  , THROTTLE_WAIT,
    leading  : no
    trailing : yes


  _handleStoreReady: ->

    osIndex = if globals.os is 'mac' then 1 else 0

    @shortcuts.config.each (collection) =>
      collectionName = collection.name

      objs = @_store.getValue collectionName

      if _.isArray objs
        _.each objs, (obj) =>

          model = @shortcuts.get collectionName, obj.name
          return  unless model

          silent = if model.options?.custom then yes else no

          # -------------------------------
          # about custom shortcuts (eg ace)
          # -------------------------------
          #
          # i don't really want to embed such logic into _shortcuts_; it should be
          # totally 'shortcut type' agnostic and api provides the necessity to deal
          # with such cases indeed.
          #
          # passing 'silent' as the 4th argument to shortcuts#update makes sure its
          # internal keyconfig#change listener won't get dispatched anyhow, thus
          # rendering the model in question unbound. plus, there is the _options_
          # object you can use to denote such weirdos.
          #
          # just make sure you don't put any 'custom shortcut' set names
          # into a bant.json file, since these sets are automatically thought to
          # be _shortcuts_ compatible.

          binding = null

          if _.isArray obj.binding
            binding = cloneArray model.binding
            binding[osIndex] = [].concat(obj.binding).filter _.isString

          @emit 'change', collection,
            shortcuts.update collectionName, obj.name,
              binding: binding
              options: options
            , silent

    # persist to app storage whenever a shortcut is changed.
    # this should handled with some care to avoid exhausting
    # resources, since _shortcuts_ emits all changes.
    @shortcuts.on 'change', _.bind @_save, this


  _handleFrontAppChange: (app, prevApp) ->
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


  get: ->
    # proxy to shortcuts#get
    # see: http://github.com/koding/shortcuts#api

    @shortcuts.get.apply @shortcuts, Array::slice.call arguments


  update: ->
    # proxy to shortcuts#update
    # see: http://github.com/koding/shortcuts#api

    unless @_store.isReady
      console.warn 'changes won\'t be persisted, since storage is not ready yet'

    @shortcuts.update @shortcuts, Array::slice.call arguments


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


  @getPlatformStorageKey: -> "#{STORAGE_NAME}-#{globals.keymapType}"
