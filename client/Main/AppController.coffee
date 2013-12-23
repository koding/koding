class AppController extends KDViewController

  constructor:->

    super

    {name, version} = @getOptions()
    @appStorage = \
      KD.singletons.appStorageController.storage name, version or "1.0"

  createContentDisplay:(models, callback)->
    warn "You need to override #createContentDisplay - #{@constructor.name}"

  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query

  registerKeyBinding: ({ binding, command, isGlobal, appName }) ->
    binding = binding.replace /\bsuper\b/g, 'mod'
    Mousetrap[if isGlobal then 'bindGlobal' else 'bind'] binding, (event) =>
      @handleCommand command, appName, event

  handleCommand: (command, appName, event) ->
    { commands } = KD.getAppOptions appName

    cmd = commands[command]
    
    if 'function' is typeof cmd
      cmd.call this, event
    else if 'string' is typeof cmd
      @[cmd]?.call this, event
    else
      throw new Error "Unknown command: #{command}"

  bindKeys: (keyBindings, appName) ->
    Mousetrap.reset()

    for { binding, command, global: isGlobal } in keyBindings
      bindings = binding  if Array.isArray binding

      if bindings?
        @registerKeyBinding { binding, command, isGlobal, appName }  for binding in bindings
      else
        @registerKeyBinding { binding, command, isGlobal, appName }


  registerKeyBindings: (appName) ->
    { keyBindings } = KD.getAppOptions appName

    @getView().on 'KeyViewIsSet', => @bindKeys keyBindings, appName