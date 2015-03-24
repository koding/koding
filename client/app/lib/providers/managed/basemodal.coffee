kd = require 'kd'
view = require './viewhelpers'

module.exports = class ManagedVMBaseModal extends kd.ModalView

  constructor: (options = {}, data) ->

    defaults = width: 640
    options  = defaults extends options

    options.cssClass = kd.utils.curry 'managed-vm modal', options.cssClass

    super options, data

    @addSubView @container = new kd.View

    @states  =
      initial: (data) =>
        view.addTo @container, message: text: 'Override this state first.'

  switchTo: (state, data)->

    @container.destroySubViews()

    unless @states[state]?
      console.warn "Requested state #{state} not found, using 'initial'."
      state = 'initial'

    stateFn = @states[state]
    stateFn data


  viewAppended: ->
    @switchTo 'initial'


  fetchKites: ->

    {queryKites} = require './helpers'

    queryKites()
      .then (kites) =>
        if kites?.length
        then @switchTo 'listKites', kites
        else @switchTo 'retry', 'No kite instance found'
      .catch (err) =>
        console.warn "Error:", err
        @switchTo 'retry', 'Failed to query kites'
