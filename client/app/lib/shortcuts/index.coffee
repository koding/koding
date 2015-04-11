Shortcuts      = require 'shortcuts'
defaults       = require './config'
_              = require 'lodash'
kd             = require 'kd'
globals        = require 'globals'
ShortcutsModal = require './views/modal'
AppController  = require 'app/appcontroller'
AppStorage     = require 'app/appstorage'
Collection     = require 'app/util/collection'

STORAGE_NAME    = 'shortcuts'
STORAGE_VERSION = '7'
DEBOUNCE_WAIT   = 300

module.exports =

class ShortcutsController extends kd.Controller

  klass = this

  # Manages keyboard shortcuts.
  #
  # Wraps over a _shortcuts_ instance by default (if not passed explicitly
  # within opts.shortcuts), and makes sure we are listening and dispatching
  # correct keyboard events depending on an application's config.
  #
  # This also exposes convenience proxy methods to the underlying _keyconfig_
  # instance, and persists the state of a keyconfig#Collection to the app storage.
  #
  constructor: (options={}, data) ->

    @_store  = null
    @_buffer = null

    if options.shortcuts instanceof Shortcuts
      @shortcuts = options.shortcuts
    else
      @shortcuts = new Shortcuts _.keys(defaults).reduce (acc, key) ->
          acc[key] = defaults[key].data
          return acc
        , {}

    @_flushBuffer()

    super options, data


  # Prepares buffer for the next batch of changes.
  #
  _flushBuffer: ->

    @_buffer = @shortcuts.config.reduce (acc, collection) ->
      acc[collection.name] = []
      return acc
    , {}

    return this


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
    appManager.on 'FrontAppIsChanged', _.bind @_handleFrontAppChange, this

    @_store.fetchStorage null, yes


  # Persists changes to app storage.
  #
  _save: _.debounce ->

    unless @_store.isReady
      console.warn 'could not persist shortcut changes'
      @_flushBuffer()
      return

    # take over buffer
    buffer = _.clone @_buffer, yes
    @_flushBuffer()

    # transform it, so we can extend the remote object
    pack =
      _
        .reduce buffer, (sum, collection, key) ->
          return collection.reduce (acc, model) ->
            name = model.name.replace /\./g, '$' # safety first
            acc["#{AppStorage.DEFAULT_GROUP_NAME}.#{key}.#{name}"] = model
            return acc
          , sum
        , {}

    # so we extend the remote object
    @_store._storage.update $set: pack, =>

      # and make sure everybody is aware of the changes we've just made
      _.each (buffer, objs, collectionName) =>
        collection = @get collectionName
        _.each objs, (value) =>
          @emit 'change', collection, collection.find name: value.name

    return

  , DEBOUNCE_WAIT


  # Buffers up changed models.
  #
  # This is necessary for not to exhaust given resources, since
  # we are listening changes in _keyconfig#Model_ level.
  #
  # That is to say, each _keyconfig#Model_ change dispatches this.
  #
  _handleShortcutsChange: (collection, model) ->

    queue   = @_buffer[collection.name]
    obj     = name: model.name
    binding = klass._getPlatformBinding model

    if (_.isArray binding) and  (not _.isEmpty binding)
      obj.binding = _.clone binding, yes
    else
      obj.binding = null

    # even if enabled is _true_ by default for this model, we always save it on
    # appstorage. defaults may change, but user overrides should stay.
    obj.enabled = if model.options?.enabled is no then no else yes

    idx = _.findIndex queue, name: model.name
    idx = if ~idx then idx else queue.length

    queue[idx] = obj

    @_save()


  # Restores overrides when storage is ready, and starts listening for changes.
  #
  _handleStoreReady: ->

    overrides = @_store._storage[AppStorage.DEFAULT_GROUP_NAME]

    _.each overrides, (objs, collectionName) =>
      collection = @shortcuts.get collectionName

      _.each objs, (override) =>
        model = collection.find name: override.name
        return  unless model

        enabled = if model.options?.enabled is no then no else yes

        matchesEnabled = override.enabled is enabled
        matchesBinding = _.isEqual klass._getPlatformBinding(model), override.binding

        unless matchesEnabled and matchesBinding
          @emit 'change', collection,
            @shortcuts.update collection.name, model.name, {
              binding: klass._replacePlatformBinding model, override.binding,
              options: enabled: override.enabled
            },
              klass._isCustomShortcut model

        return

    @shortcuts.on 'change', _.bind @_handleShortcutsChange, this

    return


  # Invalidates previous app's keyboard events and adds new
  # listeners for the current one.
  #
  _handleFrontAppChange: (app, prevApp) ->

    appId     = app?.id
    prevAppId = prevApp?.id

    return  if appId is prevAppId

    if prevApp instanceof AppController and _.isArray(sets = prevApp.getConfig().shortcuts)
      for key in sets
        @shortcuts.removeListener "key:#{key}", prevApp.bound 'handleShortcut'

    if app instanceof AppController and _.isArray(sets = app.getConfig().shortcuts)
      for key in sets
        @shortcuts.on "key:#{key}", app.bound 'handleShortcut'


  # Renders UI to manage shortcuts.
  #
  showModal: ->

    modal = new ShortcutsModal null, @toCollection()


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
  # yet it still updates the underlying _keyconfig_ instance. This is how we
  # deal with shortcuts that should be handled manually.
  #
  #
  update: (collectionName, modelName, value) ->

    throw 'value must be an object'  unless _.isObject value

    overrides = _.pick value, 'binding', 'options'

    throw 'missing \'binding\' and/or \'options\' props'  if _.isEmpty overrides
    console.warn 'changes won\'t be persisted, storage is not ready yet'  unless @_store.isReady

    model = @shortcuts.get collectionName, modelName

    throw "#{modelName} not found"  unless model

    # _lodash#pick_ returns a shallow copy; make sure we don't override the given value
    overrides = _.clone overrides, yes

    # _isNull_ test is necessary here to make sure we don't update other
    # platform bindings accidentally
    if _.isArray(overrides.binding) or _.isNull(overrides.binding)
      overrides.binding = klass._replacePlatformBinding model, overrides.binding
    else
      delete overrides.binding

    # _options.enabled_ must be precisely set to _false_ in order to disable a shortcut;
    # any other falsey setting will always be converted to _true_
    if _.isObject overrides.options
      whitelistedOptions = _.pick overrides.options, 'enabled'
      unless _.isEmpty whitelistedOptions
        overrides.options.enabled = if overrides.options.enabled is no then no else yes

    silent = klass._isCustomShortcut model
    res    = @shortcuts.update collectionName, modelName, overrides, silent

    # we manually trigger change for custom shortcuts
    if silent then @_handleShortcutsChange @shortcuts.get(collectionName), res

    return res


  # Convenience method that returns json representation of all the shortcuts
  # as a collection.
  #
  # Note that:
  #
  # * Returning value only includes bindings for the current platform.
  # * _extends_ field is used to merge a collection into the specified one.
  # That's because some shortcuts are logically in the same group and should
  # be displayed along; but in fact they are not and should be separated
  # to avoid collisions.
  #
  toJSON: ->

    extended = {}

    repr  = _
      .reduce defaults, (acc, value, key) =>
        models = @getJSON key
        parent = value.extends

        if _.isString parent
          extended[parent] = (extended[parent] or []).concat models
        else
          acc.push
            _key        : key
            title       : value.title
            description : value.description
            models      : @getJSON key
        return acc
      , []

    _.each extended, (value, key) ->
      if ~(idx = _.findIndex(repr, _key: key))
        repr[idx].models = repr[idx].models.concat value

    return repr


  # Convenience method that returns a json representation as Collection.
  #
  toCollection: ->
    new Collection @toJSON()


  # Convenience method that returns a _keyconfig#Collection's_ json representation
  # for the current platform. Optionally takes a filter predicate.
  #
  getJSON: (name, predicate) ->

    set = @shortcuts.get(name)?.chain()

    if set
      if predicate then set = set.filter predicate

      set.map (model) ->
        _.extend model.toJSON(),
          binding    : klass._getPlatformBinding model
          enabled    : if model.options?.enabled is no  then no  else yes
          hidden     : if model.options?.hidden  is yes then yes else no
          collection : name
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


  # Returns a clone of model's binding with given binding array inserted at the
  # correct position for the current platform.
  #
  @_replacePlatformBinding: (model, platformBinding) ->

    binding      = _.clone model.binding, yes
    idx          = klass._bindingPlatformIndex()
    arr          = platformBinding?.filter _.isString
    binding[idx] = if (_.isArray arr) and arr.length then arr else null

    return binding


  # Returns *true* if given _keyconfig#Model_ is a custom shortcut.
  #
  @_isCustomShortcut: (model) ->

    if model.options?.custom then yes else no
