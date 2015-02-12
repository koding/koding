class PaymentFormModal extends KDModalView

  constructor: (options = {}, data = {}) ->

    options.title    or= 'Billing information'
    options.width    or= 576
    options.height   or= 'auto'
    options.cssClass or= 'payments-modal'
    # options.theme      = 'resurrection'
    options.overlay   ?= yes

    super options, data

  viewAppended:->

    @mainLoader = new KDLoaderView
      showLoader  : yes
      size        : { width: 14 }
    @addSubView @mainLoader

    @useExistingView = new PaymentChoiceForm
    @useExistingView.hide()
    @addSubView @useExistingView

    @useExistingView.on 'PaymentMethodNotChosen', =>
      @useExistingView.hide()
      @paymentForm.show()

    @forwardEvent @useExistingView, 'PaymentMethodChosen'

    @paymentForm = new PaymentMethodEntryForm
    @paymentForm.hide()
    @addSubView @paymentForm

    @forwardEvent @paymentForm, 'PaymentInfoSubmitted'

    super()

  setState: (state, data) ->
    @mainLoader.hide()
    switch state
      when 'editExisting'
        @paymentForm.setPaymentInfo data
        @paymentForm.show()
      when 'selectPersonal'
        @useExistingView.setPaymentMethods data
        @useExistingView.show()
      else
        @paymentForm.show()

  setPaymentInfo: (paymentMethod) ->
    @paymentForm.setPaymentInfo paymentMethod

  handleRecurlyResponse:(callback, err) ->
    @paymentForm.buttons.Save.hideLoader()

    recurlyFieldMap =
      first_name         : 'cardFirstName'
      last_name          : 'cardLastName'
      number             : 'cardNumber'
      verification_value : 'cardCV'

    for e in err
      if recurlyFieldMap[e.field]
        input = @paymentForm.inputs[recurlyFieldMap[e.field]]
        input.giveValidationFeedback yes
        input.showValidationError "#{input.inputLabel?.getTitle()} #{e.message}"
      else
        input = @paymentForm.inputs.cardNumber
        input.showValidationError e.message
        input.giveValidationFeedback yes  if e.message.indexOf('card') > -1

  updateCardTypeDisplay: (cardType) ->
    @paymentForm.updateCardTypeDisplay cardType
