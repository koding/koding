kd                 = require 'kd'
KDViewController   = kd.ViewController
getAppOptions      = require './util/getAppOptions'
globals            = require 'globals'
isarray            = require 'isarray'

bants = globals.modules.reduce (acc, x) -> # todo: donot expose globals.modules
  acc[x.name] = x
  return acc
, {}

module.exports =

class AppController extends KDViewController

  constructor:->

    super

    { name, version } = @getOptions()
    { mainController, appManager, shortcuts } = kd.singletons

    mainController.ready =>
      # defer should be removed
      # this should be listening to a different event - SY
      kd.utils.defer  =>
        { appStorageController } = kd.singletons
        @appStorage = appStorageController.storage name, version or "1.0.1"

    @_active = false

    appManager.on 'AppIsBeingShown', (app) =>
      name = app.getOption('name').toLowerCase()
      keys = bants[name].shortcuts
      return  unless isarray keys

      if app is this and not @_active
        @_active = true
        for key in bants[name].shortcuts
          shortcuts.on "key:#{key}", @handleShortcut
      else if app isnt this and @_active
        @_active = false
        for key in bants[name].shortcuts
          shortcuts.removeListener "key:#{key}", @handleShortcut


  handleShortcut: (e) ->
    console.warn 'not implemented'


  createContentDisplay: (models, callback)->
    console.warn 'not implemented'


  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query
