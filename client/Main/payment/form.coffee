# PaymentForm contains the input fields that are required
# to make a purchase: Credit card number, CVC etc.
# It uses stripe.js for custom validations. If the inputs
# pass validation, it emits `PaymentSubmitted` event with
# the user inputted values.
class PaymentForm extends JView

  initialState     :
    planInterval   : PaymentWorkflow.interval.MONTH
    planTitle      : PaymentWorkflow.plan.HOBBYIST
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

    # select the inital button depending on the initial
    # button. `Month/Year`
    intervalButton = @intervalToggle.buttons[planInterval]
    @intervalToggle.buttonReceivedClick intervalButton


  initViews: ->

    { planTitle, monthPrice, yearPrice, planInterval } = @state

    { MONTH, YEAR } = PaymentWorkflow.interval

    @intervalToggle = new KDButtonGroupView
      cssClass     : 'interval-toggle'
      buttons      :
        'month'    :
          title    : 'MONTH'
          callback : => @emit 'IntervalToggleChanged', { planInterval : MONTH }
        'year'     :
          title    : 'YEAR'
          callback : => @emit 'IntervalToggleChanged', { planInterval : YEAR }


    # we are gonna process the price to make it
    # not more than 2 decimal digits.
    # basically: 124.12412412412412 -> 124.12
    monthlyDifference = (monthPrice / 100.00) - (yearPrice / 12 / 100.00)
    monthlyDifference = KD.utils.decimalAdjust 'round', monthlyDifference, -2

    @intervalToggleMessage = new KDCustomHTMLView
      cssClass : 'interval-toggle-message'
      partial  : "
        You can save <strong>$#{monthlyDifference}</strong>/mo
        by switching to <strong>yearly plan</strong>.
      "

    @plan = new KDCustomHTMLView
      cssClass: 'plan-name'
      partial : "#{planTitle.capitalize()} Plan"

    pricePartial = if planInterval is MONTH
    then "#{monthPrice / 100.00}/mo"
    else "#{yearPrice / 100.00}/yr"

    @price = new KDCustomHTMLView
      cssClass : 'plan-price'
      partial  : pricePartial


    @form = @initForm()

    # if their currentPlan is not free it means that
    # we already have their credit card, so don't show the form.
    @form.hide()  unless @state.currentPlan is PaymentWorkflow.plan.FREE

    @priceSummary = new KDCustomHTMLView
      cssClass    : 'price-summary'
      partial     : "You'll be charged $#{monthPrice / 100}/month"

    @submitButton = new KDButtonView
      disabled  : not @state.providerLoaded
      style     : 'solid medium green'
      title     : 'UPGRADE YOUR PLAN'
      loader    : yes
      cssClass  : 'submit-btn'
      callback  : =>
        # TODO: make sure the form is valid here
        @emit "PaymentSubmitted", @form.getFormData()

    @securityNote = new KDCustomHTMLView
      cssClass  : 'security-note'
      partial   : "
        <span>Secure credit card payments</span>
        Koding.com uses 128 Bit SSL Encrypted Transactions
      "


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
        cardYear.setValidationResult 'checkYear', 'Year is not valid'
      when 'exp_month'
        cardMonth.setValidationResult 'checkMonth', 'Month is not valid'
      when 'cvc'
        cardCVC.setValidationResult 'checkCVC', 'CVC is not valid'


  handlePaymentProviderLoaded: ({ provider }) ->

    @state.providerLoaded = yes

    @submitButton.enable()


  handleToggleChanged: (opts) ->

    { planInterval } = opts
    @state.planInterval = planInterval
    @form.inputs.planInterval.setValue planInterval

    { monthPrice, yearPrice } = @state

    button = @intervalToggle.buttons[planInterval]
    @intervalToggle.buttonReceivedClick button

    pricePartial = if planInterval is PaymentWorkflow.interval.MONTH
    then "#{KD.utils.decimalAdjust('round', monthPrice / 100.00, -2) }/mo"
    else "#{KD.utils.decimalAdjust('round', yearPrice / 100.00 / 12, -2)}/mo"

    @price.updatePartial pricePartial

    calculatedPrice = if planInterval is PaymentWorkflow.interval.MONTH
    then "#{KD.utils.decimalAdjust 'round', monthPrice/100, -2}/month"
    else "#{KD.utils.decimalAdjust 'round', yearPrice/100, -2}/year"

    priceSummaryPartial = "You'll be charged $#{calculatedPrice}"

    @priceSummary.updatePartial priceSummaryPartial


  showSuccess: ->

    [
      @intervalToggle
      @intervalToggleMessage
      @form
      @priceSummary
      @securityNote
    ].forEach (view) => view.destroy()

    @submitButton.setTitle 'CONTINUE'
    @submitButton.setCallback =>
      @submitButton.hideLoader()
      @emit 'PaymentWorkflowFinished', @state


  pistachio: ->
    """
    {{> @intervalToggle}}
    {{> @intervalToggleMessage}}
    <div class='summary clearfix'>
      {{> @plan}}{{> @price}}
    </div>
    {{> @form}}
    {{> @priceSummary}}
    {{> @submitButton}}
    {{> @securityNote}}
    """

