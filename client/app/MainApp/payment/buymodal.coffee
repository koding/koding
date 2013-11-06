class BuyModal extends KDModalView

  constructor: (options, data) ->
    do (o = options) ->
      o.title    ?= "Payment"
      o.cssClass ?= "group-creation-modal"
      o.height   ?= "auto"
      o.width    ?= 500
      o.overlay  ?= yes
    super options, data

  viewAppended: ->
    { productForm, confirmForm } = @getOptions()
    workflow = new PaymentWorkflow { productForm, confirmForm }
    @addSubView workflow
    @forwardEvent workflow, 'PaymentConfirmed'