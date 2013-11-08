class BuyModal extends KDModalView

  constructor: (options, data) ->
    do (o = options) ->
      o.title    ?= "Payment"
      o.height   ?= "auto"
      o.width    ?= 500
      o.overlay  ?= yes
    super options, data

  viewAppended: ->
    { workflow } = @getOptions()
    @addSubView workflow
    @forwardEvent workflow, 'PaymentConfirmed'