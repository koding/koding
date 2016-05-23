kd = require 'kd'
StackFlowController = require './controllers/stackflowcontroller'

module.exports = class ResourceStateModal extends kd.BlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'resource-state-modal', options.cssClass
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

    @stackFlow = new StackFlowController { container : this }, @getData()
    @forwardEvent @stackFlow, 'IDEBecameReady'
    @stackFlow.on 'ClosingRequested', @bound 'destroy'

    @show()


  updateStatus: (event, task) ->

    @stackFlow.updateStatus event, task


  show: ->

    { container } = @getOptions()
    @overlay      = new kd.OverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'env-modal-overlay'

    container.addSubView @overlay
    container.addSubView this


  destroy: ->

    @overlay.destroy()
    @stackFlow.destroy()
    super
