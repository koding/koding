class PaymentForm extends KDFormViewWithFields
  constructor: (options = {}, data) ->
    thisYear = (new Date).getFullYear()

    fields =

      cardFirstName       :
        label             : 'Name'
        placeholder       : 'First name'
        defaultValue      : KD.whoami().profile.firstName
        required          : 'First name is required!'
        keyup             : @bound 'updateDescription'
        nextElementFlat   :
          cardLastName    :
            placeholder   : 'Last name'
            defaultValue  : KD.whoami().profile.lastName
            required      : 'Last name is required!'

      cardDescription     :
        label             : 'Description'

      cardNumber          :
        label             : 'Credit card'
        placeholder       : 'Credit card number'
        blur              : ->
          @oldValue = @getValue()
          @setValue @oldValue.replace /\s|-/g, ''
        focus             : ->
          @setValue @oldValue  if @oldValue
        validate          :
          event           : 'blur'
          rules           :
            creditCard    : yes
            maxLength     : 16
          messages        :
            maxLength     : 'Credit card number should be 12 to 16 digits long!'
        nextElementFlat   :
          cardCV          :
            placeholder   : 'CVC'
            validate      :
              rules       :
                required  : yes
                regExp    : /[0-9]{3,4}/
              messages    :
                required  : 'Card verification code (CVC) is required!'
                regExp    : 'Card verification code (CVC) should be a 3- or 4-digit number!'

      cardMonth           :
        label             : 'Expires'
        itemClass         : KDSelectBox
        selectOptions     : __utils.getMonthOptions()
        defaultValue      : (new Date).getMonth() + 2
        nextElementFlat   :
          cardYear        :
            itemClass     : KDSelectBox
            selectOptions : (__utils.getYearOptions thisYear, thisYear + 25)
            defaultValue  : thisYear

      # company             :
      #   label             : 'Company & VAT'
      #   placeholder       : 'Company (optional)'
      #   defaultValue      : data.company
      #   nextElementFlat   :
      #     vatNumber       :
      #       placeholder   : 'VAT Number (optional)'
      #       defaultValue  : data.vatNumber

      # address1            :
      #   label             : 'Address & ZIP'
      #   placeholder       : 'Address (optional)'
      #   defaultValue      : data.address1
      #   nextElementFlat   :
      #     zip             :
      #       placeholder   : 'ZIP (optional)'
      #       defaultValue  : data.zip
      #       keyup         : @bound 'handleZipCode'

      # city                :
      #   label             : 'City & State'
      #   placeholder       : 'City (optional)'
      #   defaultValue      : data.city
      #   nextElementFlat   :
      #     state           :
      #       placeholder   : 'State (optional)'
      #       itemClass     : KDSelectBox
      #       defaultValue  : data.state

      # country             :
      #   label             : 'Country'
      #   itemClass         : KDSelectBox
      #   defaultValue      : data.country or 'US'

      # phone               :
      #   label             : 'Phone'
      #   placeholder       : '(optional)'
      #   defaultValue      : data.phone

    # options.tabs     or=

    # set up a loader to compensate for latency while we load the country list
    # @countryLoader = new KDLoaderView
    #   size        : { width: 14 }
    #   showLoader  : yes

    super
      fields                : fields
      callback              : (formData) =>
        @emit 'PaymentInfoSubmitted', @paymentMethodId, formData
      buttons               :
        Save                :
          title             : 'Save'
          style             : 'modal-clean-green'
          type              : 'submit'
          loader            : { color : '#fff', diameter : 12 }

  viewAppended:->
    super()

    { cardNumber: cardNumberInput } = @inputs

    cardNumberInput.on 'keyup', @bound 'handleCardKeyup'
    @on 'FormValidationFailed', => @buttons.Save.hideLoader()

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
    inputs.cardDescription.setPlaceHolder "#{ cardOwner }#{ cardType }"

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

  # handleZipCode:->

  #   { JLocation } = KD.remote.api

  #   { city, state, country, zip } = @inputs

  #   locationSelector =
  #     zip           : zip.getValue()
  #     countryCode   : country.getValue()

  #   JLocation.one locationSelector, (err, location) =>
  #     @setLocation location  if location

  # handleCountryCode: ->
  #   { JLocation } = KD.remote.api

  #   { country, state } = @inputs

  #   { actualState, country: countryCode } = @getData()

  #   if @countryCode isnt countryCode
  #     @countryCode = countryCode

  #     JLocation.fetchStatesByCountryCode countryCode, (err, states) ->
  #       state.setSelectOptions _.values states
  #       state.setValue actualState

  # setLocation: (location) ->
  #     ['city', 'stateCode', 'countryCode'].forEach (field) =>
  #       value = location[field]
  #       inputName = switch field
  #         when 'city' then 'city'

  #         when 'stateCode'
  #           @addCustomData 'actualState', value
  #           'state'

  #         when 'countryCode' then 'country'

  #       input = @inputs[inputName]

  #       input.setValue value  if input? # TODO: `and not input.isDirty()` or something like that C.T.

  # setCountryData: ({ countries, countryOfIp }) ->
  #   { country } = @inputs

  #   country.setSelectOptions _.values countries

  #   country.setValue(
  #     if countries[countryOfIp]
  #     then countryOfIp
  #     else 'US'
  #   )

  #   # @countryLoader.hide()
  #   @handleCountryCode()
  #   @emit 'CountryDataPopulated'
