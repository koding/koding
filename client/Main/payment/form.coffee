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

  getInitialState: -> {
    planInterval   : PaymentWorkflow.planInterval.MONTH
    planTitle      : PaymentWorkflow.planTitle.HOBBYIST
  }

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'payment-form-wrapper', options.cssClass

    super options, data

    { state } = @getOptions()

    @state = KD.utils.extend @getInitialState(), state

    @initViews()
    @initEvents()


  initViews: ->

    {
      planTitle, planInterval, reducedMonth
      currentPlan, yearPrice
    } = @state

    planIntervalPartial = if planInterval is 'month'
    then 'Monthly'
    else 'Yearly'

    @plan = new KDCustomHTMLView
      cssClass: 'plan-name'
      partial : "#{planTitle.capitalize()} Plan (#{planIntervalPartial})"

    pricePartial = @getPricePartial planInterval
    @price = new KDCustomHTMLView
      cssClass : 'plan-price'
      partial  : pricePartial

    @form = @initForm()

    @existingCreditCardMessage = new KDCustomHTMLView
      cssClass : 'existing-cc-msg'
      partial  : '
        We will use the credit card saved on your account for this purchase.
      '

    @successMessage = new KDCustomHTMLView
      cssClass : 'success-msg hidden'
      partial  : ''

    isUpgrade = PaymentWorkflow.isUpgrade currentPlan, planTitle

    buttonPartial = if isUpgrade
    then 'UPGRADE YOUR PLAN'
    else 'DOWNGRADE'

    @submitButton = new KDButtonView
      style     : 'solid medium green'
      title     : buttonPartial
      loader    : yes
      cssClass  : 'submit-btn'
      callback  : => @emit "PaymentSubmitted", @form.getFormData()

    @yearPriceMessage = new KDCustomHTMLView
      cssClass  : 'year-price-msg'
      partial   : "(You will be billed $#{yearPrice} for 12 months)"

    @securityNote = new KDCustomHTMLView
      cssClass  : 'security-note'
      partial   : "
        <span>Secure credit card payments</span>
        Koding.com uses 128 Bit SSL Encrypted Transactions
      "

    # for some cases, we need to show/hide
    # some of the subviews.
    @filterViews()


  filterViews: ->

    { FREE }  = PaymentWorkflow.planTitle
    { MONTH } = PaymentWorkflow.planInterval
    { currentPlan, planTitle, planInterval } = @state

    @yearPriceMessage.hide()  if planInterval is MONTH

    # no need to show those views when they are
    # downgrading to free account.
    if selectedPlan = planTitle is FREE
      @securityNote.hide()
      @existingCreditCardMessage.hide()
      @yearPriceMessage.hide()

    # if their currentPlan is not free it means that
    # we already have their credit card,
    # don't show existing cc message, show
    # cc form.
    if currentPlan is FREE
      @form.show()
      @existingCreditCardMessage.hide()


  initForm: ->

    { cssClass } = @getOptions()
    cssClass     = KD.utils.curry cssClass, 'hidden'

    return new StripeFormView
      state    : @state
      cssClass : cssClass
      callback : @lazyBound 'emit', 'PaymentSubmitted'


  initEvents: ->

    { cardNumber } = @form.inputs

    cardNumber.on "CreditCardTypeIdentified", (type) ->
      cardNumber.setClass type.toLowerCase()


  showValidationErrorsOnInputs: (error) ->

    @form.showValidationErrorsOnInputs error


  showSuccess: (isUpgrade) ->

    [
      @form
      @existingCreditCardMessage
      @securityNote
      @yearPriceMessage
    ].forEach (view) -> view.destroy()

    if isUpgrade
      @successMessage.updatePartial "
        Depending on the plan upgraded to, you now have access to more computing
        and storage resources.
        <a href='http://learn.koding.com/upgrade'>Learn more</a>
        about how to use your new resources.
      "
      @successMessage.show()

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
    ].forEach (view) -> view.destroy()

    [
      @$('h3')
      @$('.summary')
    ].forEach (element) -> element.hide()

    @successMessage.updatePartial "
      We are sorry that you are having trouble upgrading.
      Looks like there is an issue with the card you are
      attempting to use. If you feel the error is on our end,
      please send us relevant details at
      <a href='mailto:support@koding.com'>support@koding.com</a>
      (don't forget to include your username and the plan name
      you were trying to purchase).
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
    <h3>You have selected</h3>
    <div class='summary clearfix'>
      {{> @plan}}{{> @price}}
    </div>
    {{> @form}}
    {{> @existingCreditCardMessage}}
    {{> @successMessage}}
    {{> @yearPriceMessage}}
    {{> @submitButton}}
    {{> @securityNote}}
    """

