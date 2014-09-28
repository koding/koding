class StripeFormView extends KDFormViewWithFields

  getInitialState: -> KD.utils.dict()

  constructor: (options = {}, data) ->

    @state = KD.utils.extend @getInitialState(), options.state

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
      placeholder     : 'MM'
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
            else 'Invalid month!'
            input.setValidationResult 'checkMonth', result
        events       :
          checkMonth : 'blur'
          clear      : 'focus'
    }

    fields.cardYear = {
      label              : '&nbsp'
      placeholder        : 'YYYY'
      attributes         :
        maxlength        : 4
      validate           :
        notifications    : notificationOptions
        rules            :
          clear          : clearValidationErrors
          checkYear      : (yearInput, event) =>
            yearVal    = $.trim yearInput.getValue().replace(/-|\s/g, '')
            validMonth = (new Date).getMonth() + 1
            result = Stripe.card.validateExpiry validMonth, yearVal
            result = if result
            then no
            else 'Invalid year!'
            yearInput.setValidationResult 'checkYear', result

        events           :
          checkYear      : 'blur'
          clear          : 'focus'
    }


    { planTitle, planInterval, currentPlan } = @state

    fields.planTitle =
      defaultValue : planTitle
      cssClass     : "hidden"

    fields.planInterval =
      defaultValue : planInterval
      cssClass     : "hidden"

    fields.currentPlan =
      defaultValue : currentPlan
      cssClass     : "hidden"

    options.fields   = fields
    options.cssClass = KD.utils.curry 'payment-method-entry-form clearfix', options.cssClass
    options.name     = 'method'

    super options, data


  showValidationErrorsOnInputs: (error) ->

    { cardNumber, cardCVC, cardName
      cardMonth, cardYear } = @inputs

    switch error.param
      when 'number'
        cardNumber.setValidationResult 'checkCC', 'Card number is not valid'
      when 'exp_year'
        cardYear.setValidationResult 'checkYear', 'Invalid year!'
      when 'exp_month'
        cardMonth.setValidationResult 'checkMonth', 'Invalid month!'
      when 'cvc'
        cardCVC.setValidationResult 'checkCVC', 'CVC is not valid'



