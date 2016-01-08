kd                = require 'kd'
KDController      = kd.Controller
CreditCardModal   = require './creditcardmodal'
BaseWorkFlow      = require './baseworkflow'
PaymentConstants  = require './paymentconstants'


module.exports = class UpdateCreditCardWorkflow extends BaseWorkFlow


  { KEY, LIMIT } = PaymentConstants.FAILED_ATTEMPTS.UPDATE_CREDIT_CARD


  constructor: (options = {}, data) ->

    super options, data

    kd.singletons.appManager.tell 'Pricing', 'loadPaymentProvider', @bound 'start'


  start: ->

    { overlay } = @getOptions()

    @modal = new CreditCardModal
      cssClass       : 'CreditCardModal--update'
      overlay        : yes
      overlayOptions : { cssClass: 'CreditCardModal-overlay' }

    @modal.on 'CreditCardSubmitted',        @bound 'handleSubmit'
    @modal.on 'CreditCardWorkflowFinished', @bound 'finish'
    @emit 'ModalIsReady'


  handleSubmit: (formData) ->

    if @isExceedFailedAttemptCount LIMIT
      return @failedAttemptLimitReached()

    { cardNumber, cardCVC, cardName
      cardMonth, cardYear
    } = formData

    # Just because stripe validates both 2 digit
    # and 4 digit year, and different types of month
    # we are enforcing those, other than length problems
    # Stripe will take care of the rest. ~U
    cardYear  = null  if cardYear.length isnt 4
    cardMonth = null  if cardMonth.length isnt 2

    Stripe.card.createToken {
      number    : cardNumber
      cvc       : cardCVC
      exp_month : cardMonth
      exp_year  : cardYear
      name      : cardName
    }, (status, response) =>

      if response.error
        @modal.emit 'StripeRequestValidationFalied', response.error
        @modal.submitButton.hideLoader()
        @increaseFailedAttemptCount()
        return

      token = response.id
      @updateCreditCard token


  updateCreditCard: (token) ->

    { paymentController } = kd.singletons

    paymentController.updateCreditCard token, (err, result) =>

      if err
        @modal.emit 'CreditCardUpdateFailed', err
        @increaseFailedAttemptCount()
      else
        @modal.emit 'CreditCardUpdateSucceeded'


  finish: ->

    initiatorView = @getDelegate()

    { paymentController } = kd.singletons

    paymentController.creditCard (err, card) =>

      @emit 'UpdateCreditCardWorkflowFinishedSuccessfully', {
        paymentMethod: card
      }

      initiatorView.state.paymentMethod = card

      @modal.destroy()


  blockUserForTooManyAttempts: ->

    { appStorageController }  = kd.singletons
    accountStorage            = appStorageController.storage 'Account', '1.0'

    value   = { timestamp: Date.now() }

    accountStorage.setValue KEY, value
