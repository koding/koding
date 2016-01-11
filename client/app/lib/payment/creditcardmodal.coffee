kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView
KDButtonView      = kd.ButtonView
PaymentBaseModal  = require './paymentbasemodal'
StripeFormView    = require './stripeformview'
PaymentForm       = require './paymentform'
showError         = require '../util/showError'
nick              = require '../util/nick'


module.exports = class CreditCardModal extends PaymentBaseModal


  constructor: (options = {}, data) ->

    options.title    = 'Update Payment Method'
    options.subtitle = ''

    @isInputValidMap = {}

    super options, data


  observeForm: PaymentForm::observeForm
  handleFormInputValidation: PaymentForm::handleFormInputValidation
  handleValidationResult: PaymentForm::handleValidationResult


  initViews: ->

    @addSubView @form = new StripeFormView {
      callback : @lazyBound 'emit', 'CreditCardSubmitted'
    }

    @observeForm()

    @addSubView @successMessage = new KDCustomHTMLView
      cssClass : 'success-msg hidden'
      partial  : 'Your payment method has successfully been updated.'

    @addSubView @submitButton = new KDButtonView
      style    : 'solid medium green'
      title    : 'UPDATE'
      disabled : yes
      loader   : yes
      cssClass : 'submit-btn'
      callback : => @emit 'CreditCardSubmitted', @form.getData()

    @addSubView @securityNote = new KDCustomHTMLView
      cssClass  : 'security-note'
      partial   : "
        <span>Secure credit card payments</span>
        Koding.com uses 128 Bit SSL Encrypted Transactions
      "


  initEvents: ->

    @on 'CreditCardUpdateFailed', (err) =>
      @submitButton.hideLoader()
      showError err

    @on 'CreditCardUpdateSucceeded', @bound 'handleSuccess'
    @on 'GotValidationResult', @bound 'handleValidationResult'
    @on 'FailedAttemptLimitReached', @bound 'handleLimitReached'

    { cardNumber } = @form.inputs

    cardNumber.on 'CreditCardTypeIdentified', (tyoe) ->
      cardNumber.setClass type.toLowerCase()


  handleSuccess: ->

    @submitButton.hideLoader()

    @setTitle 'Update complete!'

    @showSuccess()

    @once 'KDModalViewDestroyed', =>
      @emit 'CreditCardWorkflowFinished'


  showSuccess: ->

    @form.hide()
    @successMessage.show()

    @submitButton.setTitle 'CONTINUE'
    @submitButton.setCallback =>
      @submitButton.hideLoader()
      @emit 'CreditCardWorkflowFinished'


  handleLimitReached: ->

    [
      @form
      @submitButton
      @securityNote
    ].forEach (view) -> view.destroy()

    @setTitle 'Too many failed attempts'
    @setSubtitle ''
    @setClass 'has-problem'

    subject = "User: #{nick()} blocked from upgrades due to too many failed attempts"

    @successMessage.updatePartial "
      Your access to upgrades has been locked for 24 hours
      due to too many failed attempts. Please try again in 24 hours.
      If you believe this is an error on our end, please send us a note at
      <a href='mailto:support@koding.com?subject=#{subject}'>
      support@koding.com</a> with
      relevant details (your username,
      plan you want to purchase, etc.).
    "
    @successMessage.show()
