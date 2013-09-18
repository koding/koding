class PaymentForm extends KDModalViewWithForms

  constructor:(options={}, data)->
    options.title    or= 'Billing Information'
    options.width    or= 520
    options.height   or= 'auto'
    options.cssClass or= 'payments-modal'
    options.overlay   ?= yes

    fields =
      cardFirstName       :
        label             : 'Name'
        placeholder       : 'First Name'
        defaultValue      : KD.whoami().profile.firstName
        validate          : @required 'First name is required!'
        nextElementFlat   :
          cardLastName    :
            placeholder   : 'Last Name'
            defaultValue  : KD.whoami().profile.lastName
            validate      : @required 'Last name is required!'

      cardNumber          :
        label             : 'Credit Card'
        placeholder       : 'Credit Card Number'
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
        defaultValue      : (new Date().getMonth())+2
        nextElementFlat   :
          cardYear        :
            itemClass     : KDSelectBox
            selectOptions : __utils.getYearOptions((new Date().getFullYear()),(new Date().getFullYear()+25))
            defaultValue  : (new Date().getFullYear())


    options.tabs     or=
      navigable                 : yes
      goToNextFormOnSubmit      : no
      forms                     :
        'Billing Info'          :
          callback              : @handleRecurlyResponse.bind this, options.callback
          buttons               :
            Save                :
              title             : 'Save'
              style             : 'modal-clean-green'
              type              : 'submit'
              loader            : { color : '#fff', diameter : 12 }
          fields                : ($.extend fields, options.additionalFields)

    super options, data

    @billingForm = @modalTabs.forms['Billing Info']
    @billingForm.inputs.cardNumber.on 'keyup', @bound 'checkCardType'
    @billingForm.on 'FormValidationFailed', => @billingForm.buttons.Save.hideLoader()

    @billingForm.fields.cardNumber.addSubView @icon = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'icon'

  clearValidation:->
    inputs = KDFormView.findChildInputs this
    input.clearValidationFeedback()  for input in inputs

  handleRecurlyResponse:(callback, err) ->
    return callback yes  unless err

    @billingForm.buttons.Save.hideLoader()

    recurlyFieldMap =
      first_name         : 'cardFirstName'
      last_name          : 'cardLastName'
      number             : 'cardNumber'
      verification_value : 'cardCV'

    for e in err
      if recurlyFieldMap[e.field]
        input = @billingForm.inputs[recurlyFieldMap[e.field]]
        input.giveValidationFeedback yes
        input.showValidationError "#{input.inputLabel?.getTitle()} #{e.message}"
      else
        input = @billingForm.inputs.cardNumber
        input.showValidationError e.message
        input.giveValidationFeedback yes  if e.message.indexOf('card') > -1

  checkCardType:->
    value = $.trim @billingForm.inputs['cardNumber'].getValue().replace(/-|\s/g,'')

    ###
    Visa:             start with a 4. New cards have 16 digits. Old cards have 13.
    MasterCard:       start with the numbers 51 through 55. All have 16 digits.
    American Express: start with 34 or 37 and have 15 digits.
    Discover:         start with 6011 or 65. All have 16 digits.
    ###

    type = if /^4/.test(value)                then 'Visa'
    else if /^5[1-5]/.test(value)             then 'MasterCard'
    else if /^3[47]/.test(value)              then 'Amex'
    else if /^6(?:011|5[0-9]{2})/.test(value) then 'Discover'
    else no

    cardType = type.toLowerCase?()
    $icon    = @icon.$()
    unless $icon.hasClass cardType
      $icon.removeClass 'visa mastercard discover amex'
      $icon.addClass cardType  if type

  required:(msg)->
    rules    : required  : yes
    messages : required  : msg
