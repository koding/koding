kd = require 'kd.js'

module.exports = class TeamPaymentTabForm extends KDFormViewWithFields

  getInitialState: -> kd.utils.dict()

  constructor: (options = {}, data) ->

    @state = kd.utils.extend @getInitialState(), options.state

    clearValidationErrors = (input, event) ->
      input.unsetTooltip()
      input.validationNotifications = {}
      input.clearValidationFeedback()
      return no

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

          checkCC    : kd.utils.debounce 100, (input, event) ->
            val = $.trim input.getValue().replace(/-|\s/g,"")
            returnResult = result = Stripe.card.validateCardNumber val
            result = if result then no else 'Card number is not valid'
            input.setValidationResult 'checkCC', result
            return returnResult
          cardType   : do =>
            cssClass = null
            return (input, event) =>
              @unsetClass cssClass  if cssClass
              val = $.trim input.getValue().replace(/-|\s/g,"")
              cssClass = Stripe.card.cardType(val).toLowerCase()
              cssClass = kd.utils.slugify cssClass
              @setClass cssClass

        events       :
          cardType   : 'keyup'
          checkCC    : ['keyup', 'blur']
          clear      : ['keydown']
    }

    fields.cardCVC = {
      label           : 'CVC'
      validate        :
        notifications : notificationOptions
        rules         :
          clear       : clearValidationErrors
          checkCVC    : (input, event) ->
            val = $.trim input.getValue().replace(/-|\s/g, '')
            returnResult = result = Stripe.card.validateCVC val
            result = if result then no else 'CVC is not valid'
            input.setValidationResult 'checkCVC', result
        events        :
          clear       : ['keydown']
          checkCVC    : ['blur', 'keyup']
    }

    fields.cardName = {
      label           : 'Name on Card'
      cssClass        : 'card-name'
      defaultValue    : ''
      validate        :
        notifications : notificationOptions
        rules         :
          clear       : clearValidationErrors
          required    : yes
        events        :
          clear       : ['keydown']
          required    : ['blur', 'keyup']
    }

    fields.cardMonth = {
      label           : 'Exp. Date'
      placeholder     : 'MM'
      attributes      :
        maxlength     : 2
      validate        :
        notifications : notificationOptions
        rules         :
          clear       : clearValidationErrors
          checkMonth  : (input, event) ->
            val = $.trim input.getValue().replace(/-|\s/g, '')

            # just to check for month, we are setting # a valid value to the year.
            validYear = (new Date).getFullYear() + 1
            returnResult = result = Stripe.card.validateExpiry val, validYear
            result = if result then no else 'Invalid month!'
            input.setValidationResult 'checkMonth', result
            return returnResult
        events       :
          clear      : ['keydown']
          checkMonth : ['blur', 'keyup']
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
            returnResult = result = Stripe.card.validateExpiry validMonth, yearVal
            result = if result then no else 'Invalid year!'
            yearInput.setValidationResult 'checkYear', result
            return returnResult

        events           :
          checkYear      : ['keyup', 'blur']
          clear          : ['keydown']
    }

    { planTitle, planInterval, currentPlan
      monthPrice, yearPrice } = @state

    fields.planTitle =
      defaultValue : planTitle
      cssClass     : "hidden"

    fields.planInterval =
      defaultValue : planInterval
      cssClass     : "hidden"

    fields.currentPlan =
      defaultValue : currentPlan
      cssClass     : "hidden"

    planAmountMap =
      year  : yearPrice
      month : monthPrice

    fields.planAmount =
      defaultValue : planAmountMap[planInterval]
      cssClass     : 'hidden'

    options.fields   = fields
    options.cssClass = kd.utils.curry 'payment-method-entry-form clearfix', options.cssClass
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
      else
        new KDNotificationView { title: error.message }


  cleanFormExceptName: ->

    [
      @inputs.cardNumber
      @inputs.cardCVC
      @inputs.cardMonth
      @inputs.cardYear
    ].forEach (input) -> input.setValue ""


  toggleInputs: (state) ->

    Object.keys(@inputs).reduce (result, key) =>
      input = @inputs[key]
      input.$().prop 'disabled', not state

