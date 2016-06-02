kd = require 'kd'
ResurceStateController = require './controllers/resourcestatecontroller'

module.exports = class ResourceStateModal extends kd.BlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'resource-state-modal', options.cssClass
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

    @off 'childAppended'

    { initial } = @getOptions()
    @controller = new ResurceStateController { container: this, initial }, @getData()
    @controller.on 'PaneDidShow', @bound 'setPositions'
    @controller.on 'ClosingRequested', @bound 'destroy'
    @forwardEvent @controller, 'IDEBecameReady'
    @forwardEvent @controller, 'MachineTurnOnStarted'

    @show()


  show: ->

    { container } = @getOptions()
    @overlay      = new kd.OverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'env-modal-overlay'

    container.addSubView @overlay
    container.addSubView this

    @setPositions()


  setPositions: ->

    { container } = @getOptions()
    { top, left } = container.getDomElement().offset()

    offset = @getDomElement().offset()

    style     =
      top     : Math.round((container.getHeight() - @getHeight()) / 2 + top)
      left    : Math.round((container.getWidth()  - @getWidth()) / 2 + left)
      opacity : 1
    @setStyle style


  updateStatus: (event, task) ->

    @controller.updateStatus event, task


  destroy: ->

    @overlay.destroy()
    @controller.destroy()

    super
