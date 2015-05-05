# PaymentForm contains the input fields that are required
# to make a purchase: Credit card number, CVC etc.
# It uses stripe.js for custom validations. If the inputs
# pass validation, it emits `PaymentSubmitted` event with
# the user inputted values.
#
# TODO: There are more than enough free month checks
# either refactor those to another type of check,
# or seperate places where we are checking for free plan
# from the rest. ~Umut


kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDButtonView = kd.ButtonView
JView = require '../jview'
PaymentConstants = require './paymentconstants'
PaypalFormView = require './paypalformview'
StripeFormView = require './stripeformview'
nick = require '../util/nick'


module.exports = class PaymentForm extends JView

  { UPGRADE, DOWNGRADE, INTERVAL_CHANGE } = PaymentConstants.operation

  getInitialState: ->
    planInterval : PaymentConstants.planInterval.MONTH
    planTitle    : PaymentConstants.planTitle.HOBBYIST
    provider     : PaymentConstants.provider.KODING


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'payment-form-wrapper', options.cssClass

    super options, data

    { state } = @getOptions()

    @state = kd.utils.extend @getInitialState(), state

    @isInputValidMap = {}

    @initViews()
    @initEvents()


  observeForm: ->

    isVisible = (key) =>
      if input = @form.inputs[key] then input.getOption('cssClass') isnt 'hidden' else no

    Object.keys(@form.inputs).filter(isVisible).map (name) =>

      input = @form.inputs[name]

      @isInputValidMap[name] = no

      input.on 'ValidationResult', (isValid) =>

        @handleFormInputValidation name, isValid


  handleFormInputValidation: (name, isValid) ->

    @isInputValidMap[name] = isValid

    formIsValid = yes
    formIsValid = formIsValid and value  for own key, value of @isInputValidMap

    @emit 'GotValidationResult', formIsValid


  initViews: ->

    {
      planTitle, planInterval, reducedMonth
      currentPlan, yearPrice, operation
    } = @state

    @plan = new KDCustomHTMLView
      cssClass: 'plan-name'
      partial : "#{planTitle.capitalize()} Plan"

    pricePartial = @getPricePartial planInterval
    @price = new KDCustomHTMLView
      cssClass : 'plan-price'
      partial  : pricePartial

    @form = @initForm()

    @observeForm()

    @existingCreditCardMessage = new KDCustomHTMLView
      cssClass : 'existing-cc-msg'
      partial  : '
        We will use the payment method saved on your account for this purchase.
      '

    @successMessage = new KDCustomHTMLView
      cssClass : 'success-msg hidden'
      partial  : ''

    buttonPartial = if @state.subscriptionState is 'expired'
    then 'CONTINUE'
    else switch operation
      when  1 then 'UPGRADE YOUR PLAN'
      when  0 then 'MAKE CHANGE'
      when -1 then 'DOWNGRADE'

    @submitButton = new KDButtonView
      style     : 'solid medium green'
      title     : buttonPartial
      loader    : yes
      disabled  : yes
      cssClass  : 'submit-btn'
      callback  : => @emit 'PaymentSubmitted', @form.getFormData()

    @paypalForm = @initPaypalForm()

    @yearPriceMessage = new KDCustomHTMLView
      cssClass  : 'year-price-msg'
      partial   : "You will be billed $#{yearPrice} for 12 months"

    @securityNote = new KDCustomHTMLView
      cssClass  : 'security-note'
      partial   : '
        <span>Secure credit card payments</span>
        Koding.com uses 128 Bit SSL Encrypted Transactions
      '

    # for some cases, we need to show/hide
    # some of the subviews.
    @filterViews()


  filterViews: ->

    { FREE }   = PaymentConstants.planTitle
    { MONTH }  = PaymentConstants.planInterval
    { KODING } = PaymentConstants.provider
    { currentPlan, planTitle, planInterval, provider, paymentMethod } = @state

    operation = PaymentConstants.getOperation currentPlan, planTitle

    @yearPriceMessage.hide()  if planInterval is MONTH
    @yearPriceMessage.hide()  if operation is PaymentConstants.operation.INTERVAL_CHANGE

    if paymentMethod
      @submitButton.enable()
      @form.hide()
    else
      @existingCreditCardMessage.hide()
      @form.show()

      # no need to show those views when they are
      # downgrading to free account.
      if planTitle is FREE
        @securityNote.hide()
        @yearPriceMessage.hide()
        @form.hide()
        @submitButton.enable()

    @paypalForm.destroy()  unless provider is KODING


  initForm: ->

    { cssClass } = @getOptions()
    cssClass     = kd.utils.curry cssClass, 'hidden'

    return new StripeFormView
      state    : @state
      cssClass : cssClass
      callback : @lazyBound 'emit', 'PaymentSubmitted'


  initPaypalForm: ->

    new PaypalFormView
      state        : @state
      buttons      :
        paypal     :
          type     : 'submit'
          domId    : 'paypal-submit'
          style    : 'solid medium green submit-btn paypal'
          title    : 'CHECKOUT USING <figure></figure>'
          callback : => @emit 'PaypalButtonClicked'


  initPaypalClient: ->

    new PAYPAL.apps.DGFlow
      expType : 'popup'
      trigger : 'paypal-submit'


  initEvents: ->

    { cardNumber } = @form.inputs

    cardNumber.on "CreditCardTypeIdentified", (type) ->
      cardNumber.setClass type.toLowerCase()

    @paypalForm.on 'PaypalTokenLoaded', @bound 'initPaypalClient'

    @on 'GotValidationResult', @bound 'handleValidationResult'


  handleValidationResult: (isValid) ->

    if isValid
    then @submitButton.enable()
    else @submitButton.disable()


  showValidationErrorsOnInputs: (error) ->

    @form.showValidationErrorsOnInputs error


  showPaypalNotAllowedStage: ->

    [
      @form
      @securityNote
      @yearPriceMessage
      @paypalForm
      @submitButton
    ].forEach (view) -> view.destroy()

    [
      @$('.divider')
      @$('.summary')
    ].forEach (view) -> view.detach()

    {operation} = @state

    word = switch operation
      when UPGRADE         then 'upgrades'
      when INTERVAL_CHANGE then 'changes'
      when DOWNGRADE       then 'downgrades'

    @existingCreditCardMessage.updatePartial "
      Sorry, #{word} are disabled for accounts using Paypal.
      Please contact <a href='mailto:billing@koding.com'>billing@koding.com</a>.
    "
    @existingCreditCardMessage.show()


  showSuccess: (operation) ->

    [
      @form
      @existingCreditCardMessage
      @securityNote
      @yearPriceMessage
      @paypalForm
    ].forEach (view) -> view.destroy()

    @$('.divider').detach()

    switch operation

      when PaymentConstants.operation.UPGRADE

        @successMessage.updatePartial "
          Sweet! You now have access to better compute
          and storage resources.
          <p>
          <b>Note:</b> You will need to resize your VM to use the additional storage. This
          <a href='http://learn.koding.com/guides/what-happens-upon-upgrade/?utm_source=upgrade_modal&utm_medium=website&utm_campaign=upgrade'
             target='_blank'>simple guide</a> shows you how to do that.
        "
        @successMessage.show()

      when PaymentConstants.operation.INTERVAL_CHANGE

        @successMessage.updatePartial "
          Your billing cycle has been successfully updated.
          Please note that this makes no change to your available
          resources.
        "
        @successMessage.show()

    @submitButton.enable()
    @submitButton.setTitle 'CONTINUE'
    @submitButton.setCallback =>
      @submitButton.hideLoader()
      @emit 'PaymentWorkflowFinished', @state


  showMaximumAttemptFailed: ->

    [
      @form
      @existingCreditCardMessage
      @securityNote
      @yearPriceMessage
      @submitButton
      @paypalForm
    ].forEach (view) -> view.destroy()

    [
      @$('.divider')
      @$('.summary')
    ].forEach (element) -> element.detach()

    subject = "User: #{nick()} blocked from upgrades due to too many failed attempts"
    body = "Plan Name: #{@state.planTitle}, Plan Interval: #{@state.planInterval}"

    @successMessage.updatePartial "
      Your access to upgrades has been locked for 24 hours
      due to too many failed attempts. Please try again in 24 hours.
      If you believe this is an error on our end, please send us a note at
      <a href='mailto:support@koding.com?subject=#{subject}&body=#{body}'>
      support@koding.com</a> with
      relevant details (your username,
      plan you want to purchase, etc.).
    "
    @successMessage.show()


  getPricePartial: (planInterval) ->

    { monthPrice, reducedMonth } = @state

    map =
      month : "#{monthPrice}<span>/month</span>"
      year  : "#{reducedMonth}<span>/month</span>"

    return map[planInterval]


  pistachio: ->
    """
    <div class='summary clearfix'>
      {{> @plan}}{{> @price}}
    </div>
    {{> @form}}
    {{> @existingCreditCardMessage}}
    {{> @successMessage}}
    {{> @yearPriceMessage}}
    {{> @submitButton}}
    #{
      if @state.provider is PaymentConstants.provider.KODING
      then '<div class="divider">OR</div>'
      else ''
    }
    {{> @paypalForm}}
    {{> @securityNote}}
    """
