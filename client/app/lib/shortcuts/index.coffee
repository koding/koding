Shortcuts      = require 'shortcuts'
defaults       = require './config'
events         = require 'events'
_              = require 'underscore'
kd             = require 'kd'
globals        = require 'globals'
ShortcutsModal = require './views/modal'
cloneArray     = require 'app/util/cloneArray'

STORAGE_NAME    = 'shortcuts'
STORAGE_VERSION = '4'
THROTTLE_WAIT   = 500

module.exports =

# Manages keyboard shortcuts.
#
# Wraps over a _shortcuts_ instance by default (if not passed explicitly
# within opts.shortcuts), and makes sure we are listening and dispatching
# correct keyboard events depending on an application's config.
#
# This also exposes convenience proxy methods to the underlying _keyconfig_
# instance, and persists the state of a keyconfig#Collection to the app storage.
#
class ShortcutsController extends events.EventEmitter

  klass = this

  constructor: (opts={}) ->

    super()

    @_store = null

    if opts.shortcuts instanceof Shortcuts
      @shortcuts = opts.shortcuts
    else
      @shortcuts = new Shortcuts _.keys(defaults).reduce (acc, key) ->
          acc[key] = defaults[key].data
          return acc
        , {}

    @_buffer = @shortcuts.config.reduce (acc, collection) ->
      acc[collection.name] = []
      return acc
    , {}


  # Party starts here.
  #
  # This adds the necessary event listeners, and fetches changes.
  # Make sure to call this after _appStorageController_ & _appManager_
  # singletons are set.
  #
  addEventListeners: ->

    { appManager, appStorageController } = kd.singletons

    @_store = appStorageController.storage
      name    : klass.getPlatformStorageKey()
      version : STORAGE_VERSION
      fetch   : no

    @_store.once 'ready', _.bind @_handleStoreReady, this

    # Add valid keyboard event listeners and invalidate obsolete upon
    # front application is set and ready.
    appManager.on 'FrontAppChange', _.bind @_handleFrontAppChange, this

    @_store.fetchStorage null, yes


  # Persists changes to app storage.
  #
  # This is a throttled method and will only be called per every
  # _THROTTLE_WAIT_ milliseconds.
  #
  _save: _.throttle ->

    throw 'could not persist changes'  unless @_store.isReady

    for key, models of @_buffer

      set = []

      while (model = @_buffer[key].pop())?
        value =
        _
          .chain(model.toJSON())
          # since every platform has independent storages, we are only
          # saving this platform's bindings
          .extend binding: klass._getPlatformBinding model
          .pick 'binding', 'options', 'name' # and nothing more
          .tap (obj) -> # to validate
            if _.isObject obj.options
              # the only whitelisted options prop is _enabled_
              obj.options = _.pick obj.options, 'enabled'
              delete obj.options  \
                if (_.isEmpty obj.options) or (not _.isBoolean obj.options.enabled)
            if (not _.isArray obj.binding) or _.isEmpty obj.binding
              delete obj.binding
          .value()

        set.push value  unless _.isEmpty value

      unless _.isEmpty set
        @_store.setValue key, set,
          _
            .chain (collectionName, modelNames) ->
              _.each modelNames, (modelName) =>
                collection = @shortcuts.get collectionName
                @emit 'change', collection, collection.find name: modelName
            .partial key, _.pluck set, 'name'
            .bind @
            .value()

  , THROTTLE_WAIT,
    leading  : no
    trailing : yes


  # Buffers up changed models.
  #
  # This is necessary for not to exhaust given resources, since
  # we are listening changes in _keyconfig#Model_ level.
  #
  # That is to say, each _keyconfig#Model_ change dispatches this.
  #
  _handleShortcutsChange: (collection, model) ->

    queue = @_buffer[collection.name]
    idx   = _.findWhere queue, name: model.name

    queue[((~idx and idx) or queue.length)] = model

    @_save()


  # Restores overrides when storage is ready, and starts listening for changes.
  #
  _handleStoreReady: ->

    @shortcuts.config.each (collection) =>
      collectionName = collection.name

      objs = @_store.getValue collectionName

      if _.isArray objs
        _.each objs, (obj) =>

          model = @shortcuts.get collectionName, obj.name
          return  unless model

          @emit 'change', collection,
            @shortcuts.update collectionName, model.name,
              binding: klass._insertPlatformBinding model, obj.binding
              options: obj.options
            , klass._isCustomShortcut model

    @shortcuts.on 'change', _.bind @_handleShortcutsChange, this


  # Invalidates previous app's keyboard events and adds new
  # listeners for the current one.
  #
  _handleFrontAppChange: (app, prevApp) ->

    appId     = app.canonicalName
    prevAppId = prevApp?.canonicalName

    return  if appId is prevAppId

    if prevApp and _.isArray(sets = prevApp.getConfig().shortcuts)
      for key in sets
        @shortcuts.removeListener "key:#{key}", prevApp.bound 'handleShortcut'

    if _.isArray(sets = app.getConfig().shortcuts)
      for key in sets
        @shortcuts.on "key:#{key}", app.bound 'handleShortcut'


  # Renders a _kd#Modal_ immediately.
  #
  showModal: ->

    new ShortcutsModal {}, @shortcuts.config


  # Proxy to _shortcuts#get_.
  #
  # See: http://github.com/koding/shortcuts#api
  #
  get: ->

    @shortcuts.get.apply @shortcuts, Array::slice.call arguments

  # Updates a _keyconfig#Model_.
  #
  # This api is pretty-much same with _shortcuts#update_.
  #
  # One important difference is _silent_ argument is handled internally,
  # and not exposed. That's because passing _silent_ to _shortcuts#update_
  # as true makes sure _shortcuts_ doesn't add any keyboard event listeners,
  # yet it still updates the underlying _keyconfig_ instance.
  #
  # This is how we deal with shortcuts that should be handled manually.
  #
  update: (collectionName, modelName, value) ->

    throw 'value must be an object'  unless _.isObject value

    overrides = _.pick value, 'binding', 'options'

    unless Object.keys(overrides).length
      throw 'value should contain \'binding\' and/or \'options\' props'

    unless @_store.isReady
      console.warn 'changes won\'t be persisted, since storage is not ready yet'

    model = @shortcuts.get collectionName, modelName
    throw "#{modelName} not found"  unless model

    if overrides.binding
      overrides.binding = klass._insertPlatformBinding model, overrides.binding

    silent = klass._isCustomShortcut model

    res = @shortcuts.update collectionName, modelName, overrides, silent

    if silent then @_handleShortcutsChange @shortcuts.get(collectionName), res

    return res


  # Convenience method that returns a _keyconfig#Collection's_ json representation
  # for the current platform. Optionally takes a filter predicate.
  #
  getJSON: (name, predicate) ->

    set = @shortcuts.get(name)?.chain()

    if set
      if predicate then set = set.filter predicate

      set.map (model) ->
        _.extend model.toJSON(), binding: klass._getPlatformBinding model
      .value()


  # Returns the app storage key for the current platform.
  #
  # This will either be *shortcuts-mac* or *shortcuts-win*.
  #
  @getPlatformStorageKey: ->

    "#{STORAGE_NAME}-#{globals.keymapType}"


  # Returns _binding_ getter method name of a _keyconfig#Model_ for the current platform.
  #
  # This is memoized, so subsequent calls will return the cached result;
  # it still must be defined at static level since _globals_ must be ready.
  #
  # This will either be *getMacKeys* or *getWinKeys*.
  #
  # See: http://github.com/koding/keyconfig#api
  #
  @_bindingGetterMethodName: _.memoize ->

    kmt = globals.keymapType
    return "get#{kmt.charAt(0).toUpperCase()}#{kmt.slice 1, 3}Keys"


  # Given a _keyconfig#Model_, returns its binding for the current platform.
  #
  @_getPlatformBinding: (model) ->

    return model[klass._bindingGetterMethodName()]()


  # Returns _binding_ array index of a _keyconfig#Model_ for the current platform.
  #
  # This is memoized, so subsequent calls will return the cached result;
  # it still must be defined at static level since _globals_ must be ready.
  #
  # This will either be 1 for mac or 0 for windows/linux.
  #
  # See: http://github.com/koding/keyconfig#spec
  #
  @_bindingPlatformIndex: _.memoize ->

    if globals.keymapType is 'mac' then 1 else 0


  # Given a keyconfig#Model and a 1d array of bindings, validates and inserts
  # the array at the correct position for the current platform, and returns
  # a deep clone of the model's binding.
  #
  @_insertPlatformBinding: (model, platformBinding) ->

    binding = cloneArray model.binding

    if _.isArray platformBinding
      binding[klass._bindingPlatformIndex()] = platformBinding.filter _.isString

    return binding


  # Returns *true* if given _keyconfig#Model_ is a custom shortcut.
  #
  @_isCustomShortcut: (model) ->

    if model.options?.custom then yes else no
