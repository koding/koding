class PaymentBaseModal extends KDModalView

  constructor: (options = {}, data) ->

    options.width    = 515
    options.cssClass = KD.utils.curry 'payment-modal', options.cssClass
    options.overlay  = yes

    super options, data

    @initViews()
    @initEvents()


  initViews: ->

  initEvents: ->

