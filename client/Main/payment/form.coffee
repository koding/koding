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

  getInitialState: ->
    planInterval : PaymentWorkflow.planInterval.MONTH
    planTitle    : PaymentWorkflow.planTitle.HOBBYIST
    provider     : PaymentWorkflow.provider.KODING


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
      currentPlan, yearPrice, isUpgrade
    } = @state

    @plan = new KDCustomHTMLView
      cssClass: 'plan-name'
      partial : "#{planTitle.capitalize()} Plan"

    pricePartial = @getPricePartial planInterval
    @price = new KDCustomHTMLView
      cssClass : 'plan-price'
      partial  : pricePartial

    @form = @initForm()

    @existingCreditCardMessage = new KDCustomHTMLView
      cssClass : 'existing-cc-msg'
      partial  : '
        We will use the payment method saved on your account for this purchase.
      '

    @successMessage = new KDCustomHTMLView
      cssClass : 'success-msg hidden'
      partial  : ''

    buttonPartial = switch isUpgrade
      when  1 then 'UPGRADE YOUR PLAN'
      when  0 then 'MAKE CHANGE'
      when -1 then 'DOWNGRADE'

    @submitButton = new KDButtonView
      style     : 'solid medium green'
      title     : buttonPartial
      loader    : yes
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

    { FREE }   = PaymentWorkflow.planTitle
    { MONTH }  = PaymentWorkflow.planInterval
    { KODING } = PaymentWorkflow.provider
    { currentPlan, planTitle, planInterval, provider } = @state

    operation = PaymentWorkflow.isUpgrade currentPlan, planTitle

    @yearPriceMessage.hide()  if planInterval is MONTH
    @yearPriceMessage.hide()  if operation is PaymentWorkflow.operation.INTERVAL_CHANGE

    # no need to show those views when they are
    # downgrading to free account.
    if planTitle is FREE
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

    @paypalForm.destroy()  unless provider is KODING


  initForm: ->

    { cssClass } = @getOptions()
    cssClass     = KD.utils.curry cssClass, 'hidden'

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

    {isUpgrade} = @state

    word = switch isUpgrade
      when  1 then 'upgrades'
      when  0 then 'changes'
      when -1 then 'downgrades'

    @existingCreditCardMessage.updatePartial "
      We are sorry #{word} are disabled for Paypal.
      Please contact <a href='mailto:billing@koding.com'>billing@koding.com</a>
    "


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

      when PaymentWorkflow.operation.UPGRADE

        @successMessage.updatePartial "
          Depending on the plan upgraded to, you now have access to more computing
          and storage resources.
          <a href='http://learn.koding.com/guides/what-happens-upon-upgrade/?utm_source=upgrade_modal&utm_medium=website&utm_campaign=upgrade'
             target='_blank'>
           Learn more
          </a>
          about how to use your new resources.
        "
        @successMessage.show()

      when PaymentWorkflow.operation.INTERVAL_CHANGE

        @successMessage.updatePartial "
          Your billing cycle has been successfully updated.
          Please note that this makes no change to your available
          resources.
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
      @$('.divider')
      @$('.summary')
    ].forEach (element) -> element.detach()

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
    <div class='summary clearfix'>
      {{> @plan}}{{> @price}}
    </div>
    {{> @form}}
    {{> @existingCreditCardMessage}}
    {{> @successMessage}}
    {{> @yearPriceMessage}}
    {{> @submitButton}}
    #{
      if @state.provider is PaymentWorkflow.provider.KODING
      then '<div class="divider">OR</div>'
      else ''
    }
    {{> @paypalForm}}
    {{> @securityNote}}
    """

