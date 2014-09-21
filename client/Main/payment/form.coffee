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
class PaymentForm extends JView

  initialState     :
    planInterval   : PaymentWorkflow.planInterval.MONTH
    planTitle      : PaymentWorkflow.planTitle.HOBBYIST
    providerLoaded : no
    validation     : {
      cardNumber   : yes
      cardCVC      : yes
      cardName     : yes
      cardMonth    : yes
      cardYear     : yes
    }

  constructor: (options = {}, data) ->

    options.cssClass = @utils.curry 'payment-form-wrapper', options.cssClass

    super options, data

    { state } = @getOptions()

    @state = @utils.extend @initialState, state

    @initViews()
    @initEvents()

    { planInterval } = state


  initViews: ->

    { MONTH, YEAR } = PaymentWorkflow.planInterval

    {
      planTitle, monthPrice, yearPrice,
      planInterval, reducedMonth, discount
      currentPlan
    } = @state

    @plan = new KDCustomHTMLView
      cssClass: 'plan-name'
      partial : "#{planTitle.capitalize()} Plan"

    pricePartial = if planInterval is MONTH
    then "#{monthPrice / 100.00}<span>/month</span>"
    else "#{yearPrice / 100.00}<span>/month</span>"

    @price = new KDCustomHTMLView
      cssClass : 'plan-price'
      partial  : pricePartial

    @discountMessage = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'discount-msg'
      partial  : "
        <strong>Save $#{discount / 100.00}</strong>/month
        by switching to a"

    @intervalToggleLink = new CustomLinkView
      state    : { planInterval: MONTH }
      cssClass : 'interval-toggle-link'
      title    : 'yearly plan'
      click    : (event) =>
        KD.utils.stopDOMEvent event
        { planInterval }  = @intervalToggleLink.getOptions().state
        switchedIntervals = { month: YEAR, year: MONTH }
        state             = { planInterval: switchedIntervals[planInterval] }
        @intervalToggleLink.setOption 'state', state
        @emit 'IntervalToggleChanged', state


    { FREE } = PaymentWorkflow.planTitle

    if planTitle is FREE
      [@discountMessage, @intervalToggleLink].forEach (view) ->
        view.hide()

    @form = @initForm()

    @existingCreditCardMessage = new KDCustomHTMLView
      cssClass : 'existing-cc-msg'
      partial  : '
        We will use the credit card saved on your account for this purchase.
      '

    @successMessage = new KDCustomHTMLView
      cssClass : 'success-msg hidden'
      partial  : ''

    # if their currentPlan is not free it means that
    # we already have their credit card,
    # so don't show the form show the existing
    # credit card message.
    @form.hide()  unless currentPlan is FREE
    @existingCreditCardMessage.hide()  if currentPlan is FREE

    isUpgrade = PaymentWorkflow.isUpgrade currentPlan, planTitle

    buttonPartial = if isUpgrade
    then 'UPGRADE YOUR PLAN FOR'
    else 'DOWNGRADE'

    @submitButton = new KDButtonView
      disabled  : not @state.providerLoaded
      style     : 'solid medium green'
      title     : buttonPartial
      loader    : yes
      cssClass  : 'submit-btn'
      callback  : => @emit "PaymentSubmitted", @form.getFormData()

    @totalPrice = new KDCustomHTMLView
      cssClass  : 'total-price'
      tagName   : 'cite'
      partial   : "#{monthPrice / 100}<span>/month</span>"

    @submitButton.addSubView @totalPrice  if isUpgrade

    @securityNote = new KDCustomHTMLView
      cssClass  : 'security-note'
      partial   : "
        <span>Secure credit card payments</span>
        Koding.com uses 128 Bit SSL Encrypted Transactions
      "

    # no need to show those views when they are
    # downgrading to free account.
    # TODO: move this into more proper place. ~U
    if planTitle is FREE
      [ @intervalToggleLink, @discountMessage
        @securityNote, @existingCreditCardMessage
      ].forEach (view) -> view.hide()


  initForm: ->

    { firstName, lastName } = KD.whoami().profile
    { planTitle, planInterval } = @state

    { cssClass } = @getOptions()

    return new StripeFormView
      state    : @state
      cssClass : cssClass
      callback : (formData) =>
        @emit "PaymentSubmitted", formData


  initEvents: ->

    @on 'IntervalToggleChanged', @bound 'handleToggleChanged'
    @on 'PaymentProviderLoaded', @bound 'handlePaymentProviderLoaded'

    { cardNumber } = @form.inputs

    cardNumber.on "CreditCardTypeIdentified", (type) ->
      cardNumber.setClass type.toLowerCase()


  showValidationErrorsOnInputs: (error) ->

    { cardNumber, cardCVC, cardName, cardMonth, cardYear } = @form.inputs

    switch error.param
      when 'number'
        cardNumber.setValidationResult 'checkCC', 'Card number is not valid'
      when 'exp_year'
        cardYear.setValidationResult 'checkYear', 'Invalid year!'
      when 'exp_month'
        cardMonth.setValidationResult 'checkMonth', 'Invalid month!'
      when 'cvc'
        cardCVC.setValidationResult 'checkCVC', 'CVC is not valid'


  handlePaymentProviderLoaded: ({ provider }) ->

    @state.providerLoaded = yes

    @submitButton.enable()


  handleToggleChanged: (opts) ->

    { MONTH }        = PaymentWorkflow.planInterval
    { planInterval } = opts

    @state.planInterval = planInterval
    @form.inputs.planInterval.setValue planInterval

    {
      monthPrice, yearPrice, reducedMonth,
      discount, currentPlan, planTitle
    } = @state

    discountPartials =
      month : "<strong>Save $#{discount / 100.00}</strong>/month by switching to"
      year  : "You are <strong>saving $#{discount * 12 / 100}</strong>. Awesome!"

    linkPartials =
      month : 'yearly plan'
      year  : 'Back to monthly plan'

    pricePartials =
      month : "#{monthPrice / 100}<span>/month</span>"
      year  : "#{reducedMonth / 100}<span>/month</span>"

    totalPricePartials =
      month : "#{monthPrice / 100}<span>/month</span>"
      year  : "#{yearPrice  / 100}<span>/year</span>"

    isUpgrade = PaymentWorkflow.isUpgrade currentPlan, planTitle

    @discountMessage.updatePartial discountPartials[planInterval]
    @intervalToggleLink.updatePartial linkPartials[planInterval]
    @price.updatePartial pricePartials[planInterval]
    @totalPrice.updatePartial totalPricePartials[planInterval]  if isUpgrade


  showSuccess: (isUpgrade) ->

    [
      @intervalToggleLink
      @discountMessage
      @form
      @existingCreditCardMessage
      @securityNote
      @totalPrice
    ].forEach (view) -> view.destroy()

    if isUpgrade
      @successMessage.updatePartial "
        Depending on the plan upgraded to, you now have access to more computing
        and storage resources.
        <a href='http://learn.koding.com'>Learn more</a>
        about how to use your new resources.
      "
      @successMessage.show()

    @submitButton.setTitle 'CONTINUE'
    @submitButton.setCallback =>
      @submitButton.hideLoader()
      @emit 'PaymentWorkflowFinished', @state


  pistachio: ->
    """
    <div class='summary clearfix'>
      {{> @plan}}{{> @price}}
    </div>
    <div class='interval-toggle-wrapper clearfix'>
      {{> @discountMessage}}{{> @intervalToggleLink}}
    </div>
    {{> @form}}
    {{> @existingCreditCardMessage}}
    {{> @successMessage}}
    {{> @submitButton}}
    {{> @securityNote}}
    """

