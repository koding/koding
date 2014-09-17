class PaymentForm extends JView

  constructor: (options = {}, data) ->

    options.cssClass = @utils.curry 'payment-form-wrapper', options.cssClass

    super options, data

    @initViews()
    @initEvents()


  initViews: ->

    { subscription, name, monthPrice, yearPrice, interval } = @state

    { MONTH, YEAR } = PaymentWorkflow.interval

    @intervalToggle = new KDButtonGroupView
      cssClass     : 'interval-toggle'
      buttons      :
        MONTH      :
          title    : MONTH
          callback : => @emit 'IntervalToggleChanged', { interval : MONTH }
        YEAR       :
          title    : YEAR
          callback : => @emit 'IntervalToggleChanged', { interval : YEAR }

    @subscription = new KDCustomHTMLView
      cssClass: 'plan-name'
      partial : "#{subscription.capitalize()} Plan"

    pricePartial = if interval is MONTH
    then "#{monthPrice / 100.00}/mo"
    else "#{yearPrice / 100.00}/yr"

    @price = new KDCustomHTMLView
      cssClass : 'plan-price'
      partial  : pricePartial


    @form = @initForm()

    @submitButton = new KDButtonView
      style     : 'solid medium green'
      title     : 'UPGRADE YOUR PLAN'
      loader    : yes
      cssClass  : 'submit-btn'

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
            monthInput = @form.inputs.cardYear
            monthVal   = $.trim monthInput.getValue().replace(/-|\s/g, '')
            yearVal    = $.trim yearInput.getValue().replace(/-|\s/g, '')

            result     = Stripe.card.validateExpiry monthVal, yearVal
            input.setValidationResult 'checkMonthYear', not result

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

    @on 'IntervalToggleChanged', (subscription) => @handleToggleChanged subscription


  handleToggleChanged: (subscription) ->

    data = @getData()
    data.subscription = subscription


  pistachio: ->
    """
    {{> @intervalToggle}}
    <div class='summary clearfix'>
      {{> @subscription}}{{> @price}}
    </div>
    {{> @form}}
    {{> @submitButton}}
    {{> @securityNote}}
    """

