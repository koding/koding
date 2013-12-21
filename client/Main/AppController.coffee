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

  registerKeyBinding: ({ binding, command, isGlobal }) ->
    binding = binding.replace /\bsuper\b/g, 'mod'
    console.log { binding, command }
    Mousetrap[if isGlobal then 'bindGlobal' else 'bind'] binding, (event) =>
      @handleCommand command, event

  handleCommand: (command) ->
    console.log command

  bindKeys: (keyBindings, commands) ->
    Mousetrap.reset()

    for { binding, command, global: isGlobal } in keyBindings
      bindings = binding  if Array.isArray binding

      if bindings?
        @registerKeyBinding { binding, command, isGlobal }  for binding in bindings
      else
        @registerKeyBinding { binding, command, isGlobal }


  registerKeyBindings: (appName) ->
    { keyBindings } = KD.getAppOptions appName

    @getView().on 'KeyViewIsSet', => @bindKeys keyBindings