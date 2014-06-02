class AppController extends KDViewController

  constructor:->

    super

    @registerKeyBindings()

    { name, version } = @getOptions()
    { mainController } = KD.singletons

    mainController.ready =>
      # defer should be removed
      # this should be listening to a different event - SY
      KD.utils.defer  =>
        { appStorageController } = KD.singletons
        @appStorage = appStorageController.storage name, version or "1.0.1"

  createContentDisplay:(models, callback)->
    warn "You need to override #createContentDisplay - #{@constructor.name}"

  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query

  registerKeyBinding: ({ binding, command, isGlobal }) ->
    binding = binding.replace /\bsuper\b/g, 'mod'
    Mousetrap[if isGlobal then 'bindGlobal' else 'bind'] binding, (event) =>
      @handleCommand command, @getOptions().name, event

  handleCommand: (command, appName, event) ->
    { commands } = KD.getAppOptions @getOptions().name

    cmd = commands[command]

    if 'function' is typeof cmd
      cmd.call this, event
    else if 'string' is typeof cmd
      @[cmd]?.call this, event
    else
      throw new Error "Unknown command: #{command}"

  bindKeys: (keyBindings) ->
    Mousetrap.reset()

    for { binding, command, global: isGlobal } in keyBindings
      bindings = binding  if Array.isArray binding

      if bindings?
        @registerKeyBinding { binding, command, isGlobal }  for binding in bindings
      else
        @registerKeyBinding { binding, command, isGlobal }


  registerKeyBindings: ->
    { keyBindings } = KD.getAppOptions @getOptions().name

    @getView().on 'KeyViewIsSet', => @bindKeys keyBindings
