kd = require 'kd'
KDBlockingModalView = kd.BlockingModalView
KDOverlayView = kd.OverlayView


module.exports = class EnvironmentsModalView extends KDBlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'env-modal', options.cssClass
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

  show: ->
    {container} = @getOptions()
    @overlay    = new KDOverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'env-modal-overlay'

    container.addSubView @overlay
    container.addSubView this

  destroy: ->
    @overlay.destroy()
    super
