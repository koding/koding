Panel = require './panel'


class Workspace extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @init()

  init: -> @createPanel()

  createPanel: ->
    options    = @getOptions()
    panelClass = options.panelClass or Panel
    @panel     = new panelClass layoutOptions: options.layoutOptions

    KD.utils.defer => @emit 'ready'

  getView: ->
    return @panel


module.exports = Workspace
