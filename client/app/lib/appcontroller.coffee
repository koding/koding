kd                 = require 'kd'
KDViewController   = kd.ViewController
getAppOptions      = require './util/getAppOptions'
globals            = require 'globals'

module.exports =

class AppController extends KDViewController

  constructor:->

    super

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
