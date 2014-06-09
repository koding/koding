class IDE.Workspace extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @init()

  init: -> @createPanel()

  createPanel: ->
    options    = @getOptions()
    panelClass = options.panelClass or IDE.Panel
    @panel     = new panelClass layoutOptions: options.layoutOptions

    KD.utils.defer => @emit 'ready'

  getView: ->
    return @panel
