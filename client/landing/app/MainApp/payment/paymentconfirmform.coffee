class PaymentConfirmForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.buttons ?= {}

    options.buttons.Buy ?=
      cssClass  : "modal-clean-green"
      callback  : => @emit 'PaymentConfirmed'

    options.buttons.cancel ?=
      cssClass  : "modal-cancel"

    super options, data

  setPaymentMethod: (method) ->
    @details.addSubView new PaymentMethodView {}, method