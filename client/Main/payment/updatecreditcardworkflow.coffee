class UpdateCreditCardWorkflow extends KDController

  constructor: (options = {}, data) ->

    super options, data

    KD.singletons.appManager.tell 'Pricing', 'loadPaymentProvider', @bound 'start'


  start: ->

    @modal = new CreditCardModal
    @modal.on 'CreditCardSubmitted',        @bound 'handleSubmit'
    @modal.on 'CreditCardWorkflowFinished', @bound 'finish'


  handleSubmit: (formData) ->

    { cardNumber, cardCVC
      cardMonth, cardYear } = formData

    # Just because stripe validates both 2 digit
    # and 4 digit year, and different types of month
    # we are enforcing those, other than length problems
    # Stripe will take care of the rest. ~U
    cardYear  = null  if cardYear.length isnt 4
    cardMonth = null  if cardMonth.length isnt 2

    Stripe.card.createToken
      number    : cardNumber
      cvc       : cardCVC
      exp_month : cardMonth
      exp_year  : cardYear
    , (status, response) =>

      if response.error
        @modal.emit 'StripeRequestValidationFalied', response.error
        @modal.submitButton.hideLoader()
        return

      token = response.id
      @updateCreditCard token


  updateCreditCard: (token) ->

    { paymentController } = KD.singletons

    paymentController.updateCreditCard token, (err, result) =>

      if err
      then @modal.emit 'CreditCardUpdateFailed', err
      else @modal.emit 'CreditCardUpdateSucceeded'


  finish: ->

    initiatorView = @getDelegate()

    { paymentController } = KD.singletons

    paymentController.creditCard (err, card) =>

      @emit 'UpdateCreditCardWorkflowFinishedSuccessfully', {
        paymentMethod: card
      }

      initiatorView.state.paymentMethod = card

      @modal.destroy()


