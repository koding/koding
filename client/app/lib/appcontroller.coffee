kd                 = require 'kd'
KDViewController   = kd.ViewController
globals            = require 'globals'

module.exports =

class AppController extends KDViewController

  constructor: ->

    super

    { name, version } = @getOptions()

    kd.singleton('mainController').ready =>
      # defer should be removed, this should be listening to a different event - SY
      kd.utils.defer  =>
        { appStorageController } = kd.singletons
        @appStorage = appStorageController.storage name, version or '1.0.1'


  getConfig: ->
    return globals.config.apps[@getOption('name')]


  handleQuery: (query) ->
    @ready => @feedController?.handleQuery? query


  handleShortcut: (e) ->
    console.warn @id + '#handleShortcut not implemented'
