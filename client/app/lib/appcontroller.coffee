kd                 = require 'kd'
KDViewController   = kd.ViewController
getAppOptions      = require './util/getAppOptions'
globals            = require 'globals'
_                  = require 'underscore'

module.exports =

class AppController extends KDViewController

  constructor:->

    super

    { name, version } = @getOptions()

    @canonicalName = name.toLowerCase() + '$' + version.toLowerCase() + '$' + _.uniqueId()

    kd.singleton('mainController').ready =>
      # defer should be removed, this should be listening to a different event - SY
      kd.utils.defer  =>
        { appStorageController } = kd.singletons
        @appStorage = appStorageController.storage name, version or "1.0.1"


  getConfig: ->
    return globals.config.apps[@getOption('name')]


  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query


  createContentDisplay: (models, callback)->
    console.warn @canonicalName + '#createContentDisplay not implemented'


  handleShortcut: (e) ->
    console.warn @canonicalName + '#handleShortcut not implemented'
