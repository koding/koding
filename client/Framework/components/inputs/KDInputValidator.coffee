class KDInputValidator
  
  @ruleRequired = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    doesValidate  = (value.length > 0)

    if doesValidate
      return null
    else
      return ruleSet.messages?.required or "Field is required!"

  @ruleEmail = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    doesValidate  = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value)

    if doesValidate
      return null
    else
      return ruleSet.messages?.email or "Please enter a valid email address!"

  @ruleMinLength = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {minLength}   = ruleSet.rules
    doesValidate  = value.length >= minLength

    if doesValidate
      return null
    else
      return ruleSet.messages?.minLength or "Please enter a value that includes more than #{minLength} characters!"

  @ruleMaxLength = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {maxLength}   = ruleSet.rules
    doesValidate  = value.length <= maxLength

    if doesValidate
      return null
    else
      return ruleSet.messages?.maxLength or "Please enter a value that includes less than #{maxLength} characters!"

  @ruleRangeLength = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {rangeLength} = ruleSet.rules
    doesValidate  = value.length <= rangeLength[1] and value.length >= rangeLength[0]

    if doesValidate
      return null
    else
      return ruleSet.messages?.rangeLength or "Please enter a value that includes more than #{rangeLength[0]} and less than #{rangeLength[0]} characters!"

  @ruleMatch = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    matchView     = ruleSet.rules.match
    matchViewVal  = $.trim matchView.getValue()
    doesValidate  = value is matchViewVal

    if doesValidate
      return null
    else
      return ruleSet.messages?.match or "Values do not match!"

  @ruleCreditCard = (input, event)->

    ###
    Visa:             start with a 4. New cards have 16 digits. Old cards have 13.
    MasterCard:       start with the numbers 51 through 55. All have 16 digits.
    American Express: start with 34 or 37 and have 15 digits.
    Diners Club:      start with 300 through 305, 36 or 38. All have 14 digits. There are Diners Club cards that begin with 5 and have 16 digits. These are a joint venture between Diners Club and MasterCard, and should be processed like a MasterCard.
    Discover:         start with 6011 or 65. All have 16 digits.
    JCB:              start with 2131 or 1800 have 15 digits. JCB cards beginning with 35 have 16 digits.
    ###

    return if event?.which is 9

    value         = $.trim input.getValue().replace(/-|\s/g,"")
    ruleSet       = input.getOptions().validate
    doesValidate  = /(^4[0-9]{12}(?:[0-9]{3})?$)|(^5[1-5][0-9]{14}$)|(^3[47][0-9]{13}$)|(^3(?:0[0-5]|[68][0-9])[0-9]{11}$)|(^6(?:011|5[0-9]{2})[0-9]{12}$)|(^(?:2131|1800|35\d{3})\d{11}$)/.test(value)

    if doesValidate
      type = if /^4[0-9]{12}(?:[0-9]{3})?$/.test(value)         then "Visa"
      else if   /^5[1-5][0-9]{14}$/.test(value)                 then "MasterCard"
      else if   /^3[47][0-9]{13}$/.test(value)                  then "Amex"
      else if   /^3(?:0[0-5]|[68][0-9])[0-9]{11}$/.test(value)  then "Diners"
      else if   /^6(?:011|5[0-9]{2})[0-9]{12}$/.test(value)     then "Discover"
      else if   /^(?:2131|1800|35\d{3})\d{11}$/.test(value)     then "JCB"
      else no
      input.emit "CreditCardTypeIdentified", type
      return null
    else
      return ruleSet.messages?.creditCard or "Please enter a valid credit card number!"
  
  @ruleJSON = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    doesValidate  = yes

    try
      JSON.parse value if value
    catch err
      error err,doesValidate
      doesValidate = no

    if doesValidate
      return null
    else
      return ruleSet.messages?.JSON or "a valid JSON is required!"

  @ruleRegExp = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {regExp}      = ruleSet.rules
    doesValidate  = regExp.test value
    
    if doesValidate
      return null
    else
      return ruleSet.messages?.regExp or "Validation failed!"


###
Credits
  email check regex:
  by Scott Gonzalez: http://projects.scottsplayground.com/email_address_validation/

###
