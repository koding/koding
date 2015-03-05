kd                 = require 'kd'
KDViewController   = kd.ViewController
KDKeyboardListener = kd.KeyboardListener
KDKeyboardMap      = kd.KeyboardMap
getAppOptions      = require './util/getAppOptions'


module.exports = class AppController extends KDViewController

  constructor:->

    super

    { name, version } = @getOptions()
    { mainController } = kd.singletons

    mainController.ready =>
      # defer should be removed
      # this should be listening to a different event - SY
      kd.utils.defer  =>
        { appStorageController } = kd.singletons
        @appStorage = appStorageController.storage name, version or "1.0.1"

    @bindKeyCombos()


  bindKeyCombos: ->

    @appKeyListener = new KDKeyboardListener
    @appKeyMap      = new KDKeyboardMap { priority: 10 }

    @appKeyListener
      .addComboMap @appKeyMap

    @registerDeclaredBindings()

    kd.singletons.appManager.on 'AppIsBeingShown', (app) =>
      @appKeyListener?.listen()  if app is this


  registerAppKeys: (bindings = {}) ->
    @appKeyMap.addCombo binding, fn  for own binding, fn of bindings
    @appKeyListener.addComboMap @appKeyMap
    @appKeyMap


  createContentDisplay:(models, callback)->
    kd.warn "You need to override #createContentDisplay - #{@constructor.name}"


  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query


  handleCommand: (command, appName, event) ->
    { commands } = getAppOptions @getOptions().name

    cmd = commands[command]

    if 'function' is typeof cmd
      cmd.call this, event
    else if 'string' is typeof cmd
      @[cmd]?.call this, event
    else
      throw new Error "Unknown command: #{command}"


  registerDeclaredBindings: ->
    appName = @getOptions().name
    { keyBindings } = getAppOptions appName

    keyBindings?.forEach (b) =>
      @appKeyMap.addCombo b.binding, { global: b.global }, (ev) =>
        @handleCommand b.command, appName, ev
