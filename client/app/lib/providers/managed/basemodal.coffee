kd = require 'kd'

module.exports = class ManagedVMBaseModal extends kd.ModalView

  constructor: (options = {}, data) ->

    defaults   =
      width    : 640
      cssClass : 'managed-vm modal'

    options    = defaults extends options

    super options, data

    @addSubView @container = new kd.View

    @states  =
      initial: (data) =>
        view.addTo @container, message: 'Override this state first.'


  switchTo: (state, data)->

    @container.destroySubViews()

    state = 'initial'  unless @states[state]?
    stateFn = @states[state]
    stateFn data


  viewAppended: ->
    @switchTo 'initial'
