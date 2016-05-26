kd = require 'kd'
ResurceStateController = require './controllers/resourcestatecontroller'

module.exports = class ResourceStateModal extends kd.BlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'resource-state-modal', options.cssClass
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

    @show()

    @controller = new ResurceStateController { container: this }, @getData()
    @controller.once 'BecameVisible', => @_windowDidResize()
    @controller.once 'ClosingRequested', @bound 'destroy'
    @forwardEvent @controller, 'IDEBecameReady'
    @forwardEvent @controller, 'MachineTurnOnStarted'


  show: ->

    { container } = @getOptions()
    @overlay      = new kd.OverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'env-modal-overlay'

    container.addSubView @overlay
    container.addSubView this


  updateStatus: (event, task) ->

    @controller.updateStatus event, task


  destroy: ->

    @overlay.destroy()
    @controller.destroy()

    super
