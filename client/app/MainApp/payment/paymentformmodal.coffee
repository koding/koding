class PaymentFormModal extends KDModalView

  constructor: (options = {}, data = {}) ->

    options.title    or= 'Billing information'
    options.width    or= 520
    options.height   or= 'auto'
    options.cssClass or= 'payments-modal'
    options.overlay   ?= yes

    super options, data

  viewAppended:->

    @mainLoader = new KDLoaderView
      showLoader  : yes
      size        : { width: 14 }

    @addSubView @mainLoader

    @useExistingView = new PaymentMethodChoiceView
    @useExistingView.hide()

    @useExistingView.on 'PaymentMethodSelected', (paymentMethodId) =>
      if paymentMethodId
        @emit 'PaymentMethodSelected', paymentMethodId
      else
        @useExistingView.hide()
        @paymentForm.show()

    @addSubView @useExistingView

    @paymentForm = new PaymentMethodEntryForm
    @paymentForm.hide()

    @forwardEvent @paymentForm, 'PaymentInfoSubmitted'
    @addSubView @paymentForm

    super()

  # showLoader:->
  #   @mainLoader.show()

  # hideLoader:->
  #   @mainLoader.hide()

  createSelectPersonalView: (paymentMethods) ->
    @useExistingView.show()
    paymentMethods.forEach (paymentMethod) =>
      @useExistingView.addPaymentMethod paymentMethod

  setState: (state, data) ->
    @mainLoader.hide()
    switch state
      when 'editExisting'
        @paymentForm.setPaymentInfo data
        @paymentForm.show()
      when 'selectPersonal'
        @createSelectPersonalView data
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