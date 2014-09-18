class StripeFormView extends KDFormViewWithFields

  initialState: {}

  constructor: (options = {}, data) ->

    @state = @utils.extend @initialState, options.state

    { firstName, lastName } = KD.whoami().profile

    clearValidationErrors = (input, event) ->
      input.unsetTooltip()
      input.validationNotifications = {}
      input.clearValidationFeedback()

    notificationOptions = { type: 'tooltip', placement: 'top' }

    fields = {}
    fields.cardNumber = {
      label          : 'Card Number'

      blur           : ->
        @oldValue = @getValue()
        @setValue @oldValue.replace /\s|-/g, ''

      focus          : -> @setValue @oldValue  if @oldValue

      validate       :
        notifications: notificationOptions
        rules        :
          clear      : clearValidationErrors

          checkCC    : (input, event) ->
            val = $.trim input.getValue().replace(/-|\s/g,"")
            result = Stripe.card.validateCardNumber val
            result = if result
            then no
            else 'Card number is not valid'
            input.setValidationResult 'checkCC', result

          cardType   : do =>
            cssClass = null
            return (input, event) =>
              @unsetClass cssClass  if cssClass
              val = $.trim input.getValue().replace(/-|\s/g,"")
              cssClass = (Stripe.card.cardType val).toLowerCase()
              cssClass = KD.utils.slugify cssClass
              @setClass cssClass

        events       :
          cardType   : 'keyup'
          checkCC    : 'blur'
          clear      : 'focus'
    }

    fields.cardCVC = {
      label           : 'CVC'
      validate        :
        notifications : notificationOptions
        rules         :
          clear       : clearValidationErrors
          checkCVC    : (input, event) ->
            val    = $.trim input.getValue().replace(/-|\s/g, '')
            result = Stripe.card.validateCVC val
            result = if result
            then no
            else 'CVC is not valid'
            input.setValidationResult 'checkCVC', result

        events        :
          clear       : 'focus'
          checkCVC    : 'blur'
    }

    fields.cardName = {
      label           : 'Name on Card'
      cssClass        : 'card-name'
      defaultValue    : "#{firstName} #{lastName}"
      validate        :
        notifications : notificationOptions
        rules         :
          clear       : clearValidationErrors
          required    : yes
        events        :
          required    : 'blur'
          clear       : 'focus'
    }

    fields.cardMonth = {
      label           : 'Exp. Date'
      attributes      :
        maxlength     : 2
      validate        :
        notifications : notificationOptions
        event         : 'blur'
        rules         :
          clear       : clearValidationErrors
          checkMonth  : (input, event) ->
            val = $.trim input.getValue().replace(/-|\s/g, '')
            # just to check for month, we are setting
            # a happy value to the year.
            result = Stripe.card.validateExpiry val, 2015
            result = if result
            then no
            else 'Month is not valid'
            input.setValidationResult 'checkMonth', result
        events       :
          checkMonth : 'blur'
          clear      : 'focus'
    }

    fields.cardYear = {
      label              : '&nbsp'
      attributes         :
        maxlength        : 4
      validate           :
        notifications    : notificationOptions
        rules            :
          clear          : clearValidationErrors
          checkMonthYear : (yearInput, event) =>
            monthInput = @inputs.cardMonth
            monthVal   = $.trim monthInput.getValue().replace(/-|\s/g, '')
            yearVal    = $.trim yearInput.getValue().replace(/-|\s/g, '')

            result     = Stripe.card.validateExpiry monthVal, yearVal
            result = if result
            then no
            else 'Year is not valid'
            yearInput.setValidationResult 'checkMonthYear', result

        events           :
          checkMonthYear : 'blur'
          clear          : 'focus'
    }

    { planTitle, planInterval } = @state

    fields.planTitle = {
      defaultValue : planTitle
      cssClass     : "hidden"
    }

    fields.planInterval = {
      defaultValue : planInterval
      cssClass     : "hidden"
    }

    options.fields   = fields
    options.cssClass = KD.utils.curry 'payment-method-entry-form clearfix', options.cssClass
    options.name     = 'method'

    super options, data


