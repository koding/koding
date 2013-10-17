class BillingFormModal extends KDModalView

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

    @useExistingView = new BillingMethodChoiceView
    @useExistingView.hide()

    @useExistingView.on 'BillingMethodSelected', (accountCode) =>
      if accountCode
        @emit 'BillingMethodSelected', accountCode
      else
        @useExistingView.hide()
        @modalTabs.show()

    @addSubView @useExistingView

    @billingForm = new BillingForm

    @forwardEvent @billingForm, 'PaymentInfoSubmitted'

    @addSubView @billingForm

    @billingForm.hide()

    super()

  # showLoader:->
  #   @mainLoader.show()

  # hideLoader:->
  #   @mainLoader.hide()

  createSelectPersonalView: (paymentMethods) ->
    @useExistingView.show()
    paymentMethods.forEach (paymentMethod) =>
      @useExistingView.addBillingMethod paymentMethod

  setState: (state, data) ->
    @mainLoader.hide()
    switch state
      when 'editExisting'
        @billingForm.setBillingInfo data
        @billingForm.show()
      when 'selectPersonal'
        @createSelectPersonalView data
      else
        @billingForm.show()

  handleFormData:->

  setBillingInfo: (billingInfo) ->
    @billingForm.setBillingInfo billingInfo

  handleRecurlyResponse:(callback, err) ->
    @billingForm.buttons.Save.hideLoader()

    recurlyFieldMap =
      first_name         : 'cardFirstName'
      last_name          : 'cardLastName'
      number             : 'cardNumber'
      verification_value : 'cardCV'

    for e in err
      if recurlyFieldMap[e.field]
        input = @billingForm.inputs[recurlyFieldMap[e.field]]
        input.giveValidationFeedback yes
        input.showValidationError "#{input.inputLabel?.getTitle()} #{e.message}"
      else
        input = @billingForm.inputs.cardNumber
        input.showValidationError e.message
        input.giveValidationFeedback yes  if e.message.indexOf('card') > -1

  updateCardTypeDisplay: (cardType) ->
    console.trace()
    @billingForm.updateCardTypeDisplay cardType
