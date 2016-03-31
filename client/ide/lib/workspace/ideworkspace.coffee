kd              = require 'kd'
KDController    = kd.Controller
IDEPanel        = require './idepanel'
module.exports  = class IDEWorkspace extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @init()

  init: -> @createPanel()

  createPanel: ->
    options    = @getOptions()
    panelClass = options.panelClass or IDEPanel
    @panel     = new panelClass { layoutOptions: options.layoutOptions }

    kd.utils.defer => @emit 'ready'

  getView: ->
    return @panel
