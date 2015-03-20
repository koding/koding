Shortcuts      = require 'shortcuts'
defaults       = require './config'
events         = require 'events'
_              = require 'underscore'
kd             = require 'kd'
os             = require 'os'
ShortcutsModal = require './views/modal'

STORAGE_VERSION      = '1'
STORAGE_BINDINGS_KEY = "bindings-#{os}"
THROTTLE_WAIT        = 300

KEYCFG_PLATFORM_METHOD_NAME = do ->
  if os is 'linux'
    platform = 'win'
  platform or= os
  return "get#{platform.charAt(0).toUpperCase()}#{platform.slice 1, 3}Keys"

module.exports =

class Keyboard extends events.EventEmitter

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
      acc[model.name] = model[KEYCFG_PLATFORM_METHOD_NAME]()
    , {}

    @_store.setValue STORAGE_BINDINGS_KEY, data

  , THROTTLE_WAIT,
    leading  : no
    trailing : yes


  _restore: ->
    throw 'not ready'  unless @_isStoreReady

    bindings = @_store.getValue(STORAGE_BINDINGS_KEY) or {}


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
