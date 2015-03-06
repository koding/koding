kd                 = require 'kd'
KDViewController   = kd.ViewController
getAppOptions      = require './util/getAppOptions'
globals            = require 'globals'
_                  = require 'underscore'

module.exports =

class AppController extends KDViewController

  constructor:->

    super

    @canonicalName = _.uniqueId name.toLowerCase() + '$' + version.toLowerCase()

    { mainController } = kd.singletons
    { name, version } = @getOptions()

    mainController.ready =>
      # defer should be removed
      # this should be listening to a different event - SY
      kd.utils.defer  =>
        { appStorageController } = kd.singletons
        @appStorage = appStorageController.storage name, version or "1.0.1"


  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query


  createContentDisplay: (models, callback)->
    console.warn 'not implemented'


  handleShortcut: (e) ->
    console.warn 'not implemented'
