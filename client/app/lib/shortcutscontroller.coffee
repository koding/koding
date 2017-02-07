Shortcuts      = require '@koding/shortcuts'
_              = require 'lodash'
kd             = require 'kd'
globals        = require 'globals'
AppController  = require './appcontroller'
AppStorage     = require './appstorage'
Collection     = require './util/collection'
events         = require 'events'
defaults       = require './defaultshortcuts.coffee'

STORAGE_NAME    = 'shortcuts'
STORAGE_VERSION = '175.3'
THROTTLE_WAIT   = 500

# On Mac we display corresponding unicode chars for the following keys.
# See: http://macbiblioblog.blogspot.nl/2005/05/special-key-symbols.html
#
MAC_UNICODE =
  shift       : '&#x21E7;'
  command     : '&#x2318;'
  alt         : '&#x2325;'
  ctrl        : '&#x2303'
  tab         : '&#x21e5'
  'caps lock' : '&#x21ea'
  space       : '&#x2423'
  enter       : '&#x23ce'
  backspace   : '&#x232b'
  home        : '&#x21f1'
  end         : '&#x21f2'
  'page up'   : '&#x21de'
  'page down' : '&#x21df'
  left        : '&#x2190'
  up          : '&#x2191'
  right       : '&#x2192'
  down        : '&#x2193'
  esc         : '&#x238b'
  'num lock'  : '&#x21ed'

# Determines the text conversion method to use when displaying bindings.
convertCase = _.capitalize

# Generates a compiled template function for rendering bindings.
renderBinding =
  _.template '<% _.forEach(keys, function (key) { %><span><%= key %></span><% }) %>'


module.exports =

class ShortcutsController extends events.EventEmitter

  klass = this

  # Manages keyboard shortcuts.
  #
  # Wraps over a shortcuts instance by default (if not passed explicitly
  # within opts.shortcuts), and makes sure we are listening and dispatching
  # correct keyboard events depending on an application's config.
  #
  # This also exposes convenience proxy methods to the underlying keyconfig
  # instance, and persists the state of a keyconfig#Collection to the app storage.
  #
  constructor: (options = {}, data) ->

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

    super()

    @setMaxListeners 0


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
  # Make sure to call this after appStorageController & appManager singletons are set.
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
  _save: _.throttle ->

    unless @_store.isReady
      console.warn 'could not persist shortcut changes'
      @_flushBuffer()
      return

    # Take over buffer.
    buffer = _.clone @_buffer, yes
    @_flushBuffer()

    appId = @_store._applicationID

    # Transform it, so we can extend the remote object.
    pack =
      _
        .reduce buffer, (sum, collection, key) ->
          return collection.reduce (acc, model) ->
            name = model.name.replace /\./g, '$' # safety first
            acc["#{AppStorage.DEFAULT_GROUP_NAME}.#{appId}.data.#{key}.#{name}"] = model
            return acc
          , sum
        , {}

    # So we extend the remote object.
    query = { $set: pack }
    @_store._storage.upsert appId, { query }, =>

      # And make sure everybody is aware of the changes we've just made.
      _.each buffer, (objs, collectionName) =>
        collection = @get collectionName
        _.each objs, (value) =>
          @emit 'change', collection, collection.find { name: value.name }

    return

  , THROTTLE_WAIT,
    leading: false
    trailing: true


  # Restores default shortcuts.
  #
  restore: (cb) ->

    unless @_store.isReady
      storeIsNotReady = 'store is not ready'
      throw storeIsNotReady

    appId = @_store._applicationID
    pack  = {}
    pack["#{AppStorage.DEFAULT_GROUP_NAME}.#{appId}.data"] = 1
    query = { $unset : pack }

    @_store._storage.upsert appId, { query }, =>

      # Remove change listeners, so we won't try to persist following changes.
      # XXX: use component-bind, bound or whatever instead
      @shortcuts.removeAllListeners 'change'

      @shortcuts.config.each (collection) =>

        collection.each (model) =>
          raw = _.find defaults[collection.name].data, { name: model.name }
          return  if raw.options?.hidden

          binding = raw.binding[klass._bindingPlatformIndex()]
          enabled = if raw.options?.enabled is no then no else yes

          @shortcuts.update collection.name, model.name, {
            binding: klass._replacePlatformBinding model, binding
            options: { enabled: enabled }
          }, klass._isCustomShortcut raw

          @emit 'change', collection, model

      @shortcuts.on 'change', _.bind @_handleShortcutsChange, this


  # Buffers up changed models.
  #
  # This is necessary for not to exhaust given resources, since we are listening
  # for changes in keyconfig#Model level.
  #
  # That is, each keyconfig#Model change dispatches this.
  #
  _handleShortcutsChange: (collection, model) ->

    queue   = @_buffer[collection.name]
    obj     = { name: model.name }
    binding = klass._getPlatformBinding model

    if (_.isArray binding) and  (not _.isEmpty binding)
      obj.binding = _.clone binding, yes
    else
      obj.binding = null

    # Even if enabled is true by default for this model, we always save it on
    # appstorage. Defaults may change, but user overrides should stay.
    obj.enabled = if model.options?.enabled is no then no else yes

    idx = _.findIndex queue, { name: model.name }
    idx = if ~idx then idx else queue.length

    queue[idx] = obj

    @_save()


  # Restores overrides when storage is ready, and starts listening for changes.
  #
  _handleStoreReady: ->

    appId     = @_store._applicationID
    overrides = @_store._storage[AppStorage.DEFAULT_GROUP_NAME]?[appId]?.data ? []

    _.each overrides, (objs, collectionName) =>
      collection = @shortcuts.get collectionName

      _.each objs, (override) =>
        model = collection.find { name: override.name }
        return  unless model

        enabled = if model.options?.enabled is no then no else yes

        matchesEnabled = override.enabled is enabled
        matchesBinding = _.isEqual klass._getPlatformBinding(model), override.binding

        unless matchesEnabled and matchesBinding
          @emit 'change', collection,
            @shortcuts.update collection.name, model.name, {
              binding: klass._replacePlatformBinding model, override.binding
              options: { enabled: override.enabled }
            }, klass._isCustomShortcut model

        return

    @shortcuts.on 'change', _.bind @_handleShortcutsChange, this

    return


  # Invalidates previous app's keyboard events and adds new listeners
  # for the current one.
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


  # Proxy to shortcuts#get.
  #
  # See: http://github.com/koding/shortcuts#api
  #
  get: ->

    @shortcuts.get.apply @shortcuts, Array::slice.call arguments


  # Updates a keyconfig#Model.
  #
  # This api is pretty-much same with shortcuts#update.
  #
  # One important difference is silent argument is handled internally,
  # and not exposed. That's because passing silent to shortcuts#update
  # as true makes sure shortcuts doesn't add any keyboard event listeners,
  # yet it still updates the underlying keyconfig instance. This is how we
  # deal with shortcuts that should be handled manually.
  #
  update: (collectionName, modelName, value) ->

    objectValue = 'value must be an object'
    throw objectValue  unless _.isObject value

    overrides = _.pick value, 'binding', 'options'

    emptyOverrides = 'missing \'binding\' and/or \'options\' props'
    throw emptyOverrides  if _.isEmpty overrides
    console.warn 'changes won\'t be persisted, storage is not ready yet'  unless @_store.isReady

    model = @shortcuts.get collectionName, modelName

    notFoundModel = "#{modelName} not found"
    throw notFoundModel  unless model

    # lodash#pick returns a shallow copy; make sure we don't override the given value.
    overrides = _.clone overrides, yes

    # isNull test is necessary here to make sure we don't update other
    # platform bindings accidentally.
    if _.isArray(overrides.binding) or _.isNull(overrides.binding)
      overrides.binding = klass._replacePlatformBinding model, overrides.binding
    else
      delete overrides.binding

    # options.enabled must be precisely set to false in order to disable a shortcut;
    # any other falsey setting will always be converted to true.
    if _.isObject overrides.options
      whitelistedOptions = _.pick overrides.options, 'enabled'
      unless _.isEmpty whitelistedOptions
        overrides.options.enabled = if overrides.options.enabled is no then no else yes

    silent = klass._isCustomShortcut model
    res    = @shortcuts.update collectionName, modelName, overrides, silent

    # We manually dispatch change for custom shortcuts.
    if silent then @_handleShortcutsChange @shortcuts.get(collectionName), res

    return res


  # Convenience method that returns json representation of all the shortcuts
  # as a collection.
  #
  # Note that:
  #
  # * Returning value only includes bindings for the current platform.
  # * extends field is used to merge a collection into the specified one.
  # That's because some shortcuts are logically in the same group and should
  # be displayed along; but in fact they are not and should be separated
  # to avoid collisions. (XXX: extends stuff is obsolete)
  #
  toJSON: (predicate) ->

    extended = {}

    repr  = _
      .reduce defaults, (acc, value, key) =>
        models = @getJSON key, predicate
        parent = value.extends

        if _.isString parent
          extended[parent] = (extended[parent] or []).concat models
        else
          acc.push
            _key        : key
            title       : value.title
            description : value.description
            models      : @getJSON key, predicate
        return acc
      , []

    _.each extended, (value, key) ->
      if ~(idx = _.findIndex(repr, { _key: key }))
        repr[idx].models = repr[idx].models.concat value

    return repr


  # Convenience method that returns a json representation as Collection.
  #
  toCollection: (predicate) ->
    new Collection @toJSON predicate


  # Convenience method that returns a keyconfig#Collection's json representation
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


  # Pauses shortcuts.
  #
  pause: -> @shortcuts.pause()


  # Unpauses shortcuts.
  #
  unpause: -> @shortcuts.unpause()


  # Given a collection name, returns colliding shortcut models grouped by
  # colliding bindings for the current platform only.
  #
  getCollisions: (name) ->
    @shortcuts.getCollisions name


  # Given a collection name, returns colliding shortcut model names non-grouped
  # for the current platform.
  #
  getCollisionsFlat: (name) ->
    _
      .chain @getCollisions name
      .flatten()
      .map 'name'
      .value()


  # Returns the app storage key for the current platform.
  #
  # This will either be shortcuts-mac or shortcuts-win.
  #
  @getPlatformStorageKey: ->

    "#{STORAGE_NAME}-#{globals.keymapType}"


  # Returns binding getter method name of a keyconfig#Model for the current platform.
  #
  # This is memoized, so subsequent calls will return the cached result;
  # it still must be defined at static level since globals must be ready.
  #
  # This will either be getMacKeys or getWinKeys.
  #
  # See: http://github.com/koding/keyconfig#api
  #
  @_bindingGetterMethodName: _.memoize ->

    kmt = globals.keymapType
    return "get#{kmt.charAt(0).toUpperCase()}#{kmt.slice 1, 3}Keys"


  # Given a keyconfig#Model, returns its binding for the current platform.
  #
  @_getPlatformBinding: (model) ->

    return model[klass._bindingGetterMethodName()]()

  getPlatformBinding: klass._getPlatformBinding


  # Returns binding array index of a keyconfig#Model for the current platform.
  #
  # This is memoized, so subsequent calls will return the cached result;
  # it still must be defined at static level since globals must be ready.
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

    return null  if not model or not platformBinding

    binding      = _.clone model.binding, yes
    idx          = klass._bindingPlatformIndex()
    arr          = platformBinding?.filter? _.isString
    binding[idx] = if (_.isArray arr) and arr.length then arr else null

    return binding


  # Returns true if given keyconfig#Model is a custom shortcut.
  #
  @_isCustomShortcut: (model) ->

    if model.options?.custom then yes else no


  # Returns a html string presentation for the given binding array or string.
  #
  @presentBinding = (keys) ->

    if _.isString keys then keys = keys.split '+'

    renderBinding { keys:
      if globals.os isnt 'mac'
      then _.map keys, (value) -> convertCase value
      else _.map keys, (value) -> MAC_UNICODE[value] or convertCase value
    }
