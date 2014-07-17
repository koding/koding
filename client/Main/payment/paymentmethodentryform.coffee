class PaymentMethodEntryForm extends KDFormViewWithFields
  constructor: (options = {}, data) ->

    thisYear = expiresYear = (new Date).getFullYear()

    expiresMonth = (new Date).getMonth() + 2

    if expiresMonth > 12
      expiresYear   += 1
      expiresMonth  %= 12

    fields =
      cardFirstName       :
        placeholder       : 'First name'
        defaultValue      : KD.whoami().profile.firstName
        validate          :
          notifications   : yes
          event           : "blur"
          rules           :
            required      : yes
          messages        :
            required      : 'First name is required!'
        keyup             : @bound 'updateDescription'
        cssClass          : "card-name"
        nextElementFlat   :
          cardLastName    :
            placeholder   : 'Last name'
            defaultValue  : KD.whoami().profile.lastName
            validate      :
              notifications: yes
              event       : "blur"
              rules       :
                required  : yes
              messages    :
                required  : 'Last name is required!'

      cardNumber          :
        placeholder       : 'Credit card number'
        blur              : ->
          @oldValue = @getValue()
          @setValue @oldValue.replace /\s|-/g, ''
        focus             : ->
          @setValue @oldValue  if @oldValue
        validate          :
          notifications   : yes
          event           : 'blur'
          rules           :
            creditCard    : yes
            maxLength     : 16
          messages        :
            maxLength     : 'Credit card number should be 12 to 16 digits long!'

      cardMonth           :
        placeholder       : "MM"
        maxLength         : 2
        validate          :
          notifications   : yes
          event           : 'blur'
          rules           :
            maxLength     : 2
          messages        :
            regExp        : "Expiration month should be 2 digits and between 01 to 12"
        nextElementFlat   :
          cardYear        :
            placeholder   : "YY"
            maxLength     : 2
            validate      :
              notifications: yes
              event       : 'blur'
              rules       :
                regExp    : do ->
                  twoDigitsYear = (new Date).getFullYear()%100
                  yearOptions   = [twoDigitsYear...twoDigitsYear+15].join '|'
                  return ///#{yearOptions}///
              messages    :
                regExp    : "Expiration year should be between #{twoDigitsYear = (new Date).getFullYear()%100} to #{twoDigitsYear+14}"
      cardCV              :
        placeholder       : 'CVC'
        validate          :
          notifications   : yes
          event           : 'blur'
          rules           :
            regExp        : /^[0-9]{3,4}$/
          messages        :
            regExp        : 'Card verification code (CVC) should be a 3 or 4-digit number!'
      captcha             :
        itemClass         : KDCustomHTMLView
        domId             : "recaptcha"

    super
      cssClass              : KD.utils.curry 'payment-method-entry-form', options.cssClass
      name                  : 'method'
      fields                : fields
      callback              : (formData) =>
        @emit 'PaymentInfoSubmitted', @paymentMethodId, formData
      buttons               :
        Save                :
          title             : 'ADD CARD'
          style             : 'solid medium green'
          type              : 'submit'
          loader            : yes
        BACK                :
          style             : 'medium solid light-gray to-left'
          callback          : => @parent.showForm 'choice'

  stopLoader:-> @buttons.Save.hideLoader()

  viewAppended:->
    super()

    { cardNumber: cardNumberInput } = @inputs
    cardNumberInput.on 'keyup', @bound 'handleCardKeyup'

    @on 'FormValidationFailed', (err)=>
      KD.utils.wait 500, => @unsetClass 'animate shake'
      @setClass 'animate shake'
      @stopLoader()

    cardNumberInput.on "ValidationError", ->
      @parent.unsetClass "visa mastercard amex diners discover jcb"

    cardNumberInput.on "CreditCardTypeIdentified", (type)->
      @parent.unsetClass "visa mastercard amex diners discover jcb"
      cardType = type.toLowerCase()
      @parent.setClass cardType

    @fields.cardNumber.addSubView @icon = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'icon'

    # @paymentForm.fields.country.addSubView @countryLoader

    @updateDescription()

    @addCaptcha()

  addCaptcha:->
    Recaptcha.create KD.config.recaptcha,
      "recaptcha",
      RecaptchaDefaultOptions

  activate: ->
    { cardFirstName, cardLastName, cardNumber } = @inputs
    for input in [cardFirstName, cardLastName, cardNumber]
      return input.setFocus()  unless input.getValue()

  getCardInputValue:->
    @inputs.cardNumber.getValue().replace /-|\s/g, ''

  getCardType: (value = @getCardInputValue()) ->
    ###
    Visa:             start with a 4. New cards have 16 digits. Old cards have 13.
    MasterCard:       start with the numbers 51 through 55. All have 16 digits.
    American Express: start with 34 or 37 and have 15 digits.
    Discover:         start with 6011 or 65. All have 16 digits.
    ###
    switch
      when /^4/.test(value)                   then 'Visa'
      when /^5[1-5]/.test(value)              then 'MasterCard'
      when /^3[47]/.test(value)               then 'Amex'
      when /^6(?:011|5[0-9]{2})/.test(value)  then 'Discover'
      else                                         'Unknown'

  updateCardTypeDisplay: (cardType = @getCardType()) ->
    @addCustomData 'cardType', cardType
    cardType = cardType.toLowerCase()
    $icon    = @icon.$()
    unless $icon.hasClass cardType
      $icon.removeClass 'visa mastercard discover amex unknown'
      $icon.addClass cardType  if cardType
    @updateDescription()

  updateDescription: ->
    { inputs } = this
    formData = @getData()
    cardFirstName = inputs.cardFirstName.getValue()
    cardType = switch formData.cardType
      when 'Unknown', undefined then 'credit card'
      else formData.cardType
    cardOwner = if cardFirstName then "#{ cardFirstName }'s " else ''
    # inputs.cardDescription.setPlaceHolder "#{ cardOwner }#{ cardType }"

  handleCardKeyup: (event) -> @updateCardTypeDisplay()

  setPaymentInfo: (paymentMethod) ->
    @paymentMethodId = paymentMethod.paymentMethodId
    for own key, value of paymentMethod.billing
      switch key
        when 'state'
          @addCustomData 'actualState', value
        when 'cardType'
          @updateCardTypeDisplay value
        when 'cardNumber', 'cardCV'
          @inputs[key]?.setPlaceHolder value
        when 'address2' then # ignore
        else
          @inputs[key]?.setValue value

  clearValidation:->
    inputs = KDFormView.findChildInputs this
    input.clearValidationFeedback()  for input in inputs
