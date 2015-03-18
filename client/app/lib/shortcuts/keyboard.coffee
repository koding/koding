Shortcuts = require 'shortcuts'
defaults  = require './defaults'
events    = require 'events'
_         = require 'underscore'
kd        = require 'kd'

STORAGE_VERSION = '1'

module.exports =

class Keyboard extends events.EventEmitter

  constructor: (opts={}) ->

    super()

    if opts.shortcuts instanceof Shortcuts
      @shortcuts = opts.shortcuts
    else
      raw = _.keys(defaults).reduce (acc, key) ->
        acc[key] = defaults[key].data
        return acc
      , {}
      @shortcuts = new Shortcuts raw

    { appStorageController } = kd.singletons
    @_store = appStorageController.storage 'Keyboard', STORAGE_VERSION


  start: ->
    @addEventListeners()


  addEventListeners: ->

    { appManager } = kd.singletons
    appManager.on 'FrontAppChange', 
      _.bind @handleFrontAppChange, this


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
