# PaymentForm contains the input fields that are required
# to make a purchase: Credit card number, CVC etc.
# It uses stripe.js for custom validations. If the inputs
# pass validation, it emits `PaymentSubmitted` event with
# the user inputted values.
class PaymentForm extends JView

  initialState     :
    interval       : PaymentWorkflow.interval.MONTH
    plan           : PaymentWorkflow.plan.HOBBYIST
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

    { interval } = state

    # select the inital button depending on the initial
    # button. `Month/Year`
    intervalButton = @intervalToggle.buttons[interval]
    @intervalToggle.buttonReceivedClick intervalButton


  initViews: ->

    { planName, name, monthPrice, yearPrice, interval } = @state

    { MONTH, YEAR } = PaymentWorkflow.interval

    @intervalToggle = new KDButtonGroupView
      cssClass     : 'interval-toggle'
      buttons      :
        'month'    :
          title    : 'MONTH'
          callback : => @emit 'IntervalToggleChanged', { interval : MONTH }
        'year'     :
          title    : 'YEAR'
          callback : => @emit 'IntervalToggleChanged', { interval : YEAR }


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
      partial : "#{planName.capitalize()} Plan"

    pricePartial = if interval is MONTH
    then "#{monthPrice / 100.00}/mo"
    else "#{yearPrice / 100.00}/yr"

    @price = new KDCustomHTMLView
      cssClass : 'plan-price'
      partial  : pricePartial


    @form = @initForm()

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

    fields = {}
    fields.cardNumber = {
      label             : 'Card Number'

      blur              : ->
        @oldValue = @getValue()
        @setValue @oldValue.replace /\s|-/g, ''

      focus          : -> @setValue @oldValue  if @oldValue

      validate       :
        rules        :
          required   : yes
          checkCC    : (input, event) ->
            val = $.trim input.getValue().replace(/-|\s/g,"")
            result = Stripe.card.validateCardNumber val
            input.setValidationResult 'checkCC', not result
          cardType   : do =>
            cssClass = null
            return (input, event) =>
              @form.unsetClass cssClass  if cssClass
              val = $.trim input.getValue().replace(/-|\s/g,"")
              cssClass = (Stripe.card.cardType val).toLowerCase()
              cssClass = KD.utils.slugify cssClass
              @form.setClass cssClass

        events       :
          cardType   : 'keyup'
          required   : 'blur'
          checkCC    : 'blur'
    }

    fields.cardCVC = {
      label         : 'CVC'
      validate      :
        rules       :
          required  : yes
          minLength : 3
          checkCVC  : (input, event) ->
            val    = $.trim input.getValue().replace(/-|\s/g, '')
            result = Stripe.card.validateCVC val
            input.setValidationResult 'checkCVC', not result

        events      :
          required  : 'blur'
          checkCVC  : 'blur'
          minLength : 'blur'
    }

    fields.cardName = {
      label        : 'Name on Card'
      cssClass     : 'card-name'
      defaultValue : "#{firstName} #{lastName}"
      validate     :
        rules      :
          required : yes
        events     :
          required : 'blur'
    }

    fields.cardMonth = {
      label          : 'Exp. Date'
      attributes     :
        maxlength    : 2
      validate       :
        event        : 'blur'
        rules        :
          required   : yes
          checkMonth : (input, event) ->
            val = $.trim input.getValue().replace(/-|\s/g, '')
            # just to check for month, we are setting
            # a happy value to the year.
            result = Stripe.card.validateExpiry val, 2015
            input.setValidationResult 'checkMonth', not result
        events       :
          required   : 'blur'
          checkMonth : 'blur'
    }

    fields.cardYear = {
      label              : '&nbsp'
      attributes         :
        maxlength        : 4
      validate           :
        rules            :
          checkMonthYear : (yearInput, event) =>
            monthInput = @form.inputs.cardMonth
            monthVal   = $.trim monthInput.getValue().replace(/-|\s/g, '')
            yearVal    = $.trim yearInput.getValue().replace(/-|\s/g, '')

            result     = Stripe.card.validateExpiry monthVal, yearVal
            yearInput.setValidationResult 'checkMonthYear', not result

        events           :
          checkMonthYear : 'blur'
    }

    { cssClass } = @getOptions()

    return new KDFormViewWithFields
      cssClass : KD.utils.curry 'payment-method-entry-form clearfix', cssClass
      name     : 'method'
      fields   : fields
      callback : (formData) => @emit "PaymentSubmitted", formData


  initEvents: ->

    @on 'IntervalToggleChanged', @bound 'handleToggleChanged'
    @on 'PaymentProviderLoaded', @bound 'handlePaymentProviderLoaded'

    { cardNumber } = @form.inputs

    cardNumber.on "CreditCardTypeIdentified", (type) ->
      cardNumber.setClass type.toLowerCase()


  handlePaymentProviderLoaded: ({ provider }) ->

    @state.providerLoaded = yes

    @submitButton.enable()


  handleToggleChanged: (opts) ->

    { interval } = opts
    @state.interval = interval

    { monthPrice, yearPrice } = @state

    button = @intervalToggle.buttons[interval]
    @intervalToggle.buttonReceivedClick button

    pricePartial = if interval is PaymentWorkflow.interval.MONTH
    then "#{KD.utils.decimalAdjust('round', monthPrice / 100.00, -2) }/mo"
    else "#{KD.utils.decimalAdjust('round', yearPrice / 100.00 / 12, -2)}/mo"

    @price.updatePartial pricePartial

    calculatedPrice = if interval is PaymentWorkflow.interval.MONTH
    then "#{KD.utils.decimalAdjust 'round', monthPrice/100, -2}/month"
    else "#{KD.utils.decimalAdjust 'round', yearPrice/100, -2}/year"

    priceSummaryPartial = "You'll be charged $#{calculatedPrice}"

    @priceSummary.updatePartial priceSummaryPartial


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

