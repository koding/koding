kd = require 'kd'
KDModalView = kd.ModalView
module.exports = class PaymentBaseModal extends KDModalView

  constructor: (options = {}, data) ->

    options.width    = 515
    options.cssClass = kd.utils.curry 'payment-modal', options.cssClass
    options.overlay  = yes

    super options, data

    @initViews()
    @initEvents()


  initViews: ->

  initEvents: ->
