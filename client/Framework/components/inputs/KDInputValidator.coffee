class KDInputValidator

  @ruleRequired = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    doesValidate  = (value.length > 0)

    if doesValidate
      return null
    else
      return ruleSet.messages?.required or "Field is required"

  @ruleEmail = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    doesValidate  = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value)

    if doesValidate
      return null
    else
      return ruleSet.messages?.email or "Please enter a valid email address"

  @ruleMinLength = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {minLength}   = ruleSet.rules
    doesValidate  = value.length >= minLength

    if doesValidate
      return null
    else
      return ruleSet.messages?.minLength or "Please enter a value that has #{minLength} characters or more"

  @ruleMaxLength = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {maxLength}   = ruleSet.rules
    doesValidate  = value.length <= maxLength

    if doesValidate
      return null
    else
      return ruleSet.messages?.maxLength or "Please enter a value that has #{maxLength} characters or less"

  @ruleRangeLength = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {rangeLength} = ruleSet.rules
    doesValidate  = value.length <= rangeLength[1] and value.length >= rangeLength[0]

    if doesValidate
      return null
    else
      return ruleSet.messages?.rangeLength or "Please enter a value that has more than #{rangeLength[0]} and less than #{rangeLength[1]} characters"

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
      return ruleSet.messages?.match or "Values do not match"

  @ruleCreditCard = (input, event)->
    return if event?.which is 9

    value = $.trim input.getValue().replace(/-|\s/g,'')
    regex = /(^4[0-9]{12}(?:[0-9]{3})?$)|(^5[1-5][0-9]{14}$)|(^3[47][0-9]{13}$)|(^3(?:0[0-5]|[68][0-9])[0-9]{11}$)|(^6(?:011|5[0-9]{2})[0-9]{12}$)|(^(?:2131|1800|35\d{3})\d{11}$)/
    return null  if regex.test(value)
    return input.getOptions().validate.messages?.creditCard or 'Please enter a valid credit card number'

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
      return ruleSet.messages?.JSON or "a valid JSON is required"

  @ruleRegExp = (input, event)->

    return if event?.which is 9

    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    {regExp}      = ruleSet.rules
    doesValidate  = regExp.test value

    if doesValidate
      return null
    else
      return ruleSet.messages?.regExp or "Validation failed"

  @ruleUri = (input, event)->

    return if event?.which is 9

    regExp = ///
        ^
        	([a-z0-9+.-]+):							                            #scheme
        	(?:
        		//							                                      #it has an authority:
        		(?:((?:[a-z0-9-._~!$&'()*+,;=:]|%[0-9A-F]{2})*)@)?	  #userinfo
        		((?:[a-z0-9-._~!$&'()*+,;=]|%[0-9A-F]{2})*)		        #host
        		(?::(\d*))?						                                #port
        		(/(?:[a-z0-9-._~!$&'()*+,;=:@/]|%[0-9A-F]{2})*)?	    #path
        		|
        									                                        #it doesn't have an authority:
        		(/?(?:[a-z0-9-._~!$&'()*+,;=:@]|%[0-9A-F]{2})+(?:[a-z0-9-._~!$&'()*+,;=:@/]|%[0-9A-F]{2})*)?	#path
        	)
        	(?:
        		\?((?:[a-z0-9-._~!$&'()*+,;=:/?@]|%[0-9A-F]{2})*)	    #query string
        	)?
        	(?:
        		#((?:[a-z0-9-._~!$&'()*+,;=:/?@]|%[0-9A-F]{2})*)	    #fragment
        	)?
        	$
    ///i
    value         = $.trim input.getValue()
    ruleSet       = input.getOptions().validate
    doesValidate  = regExp.test value

    if doesValidate
      return null
    else
      return ruleSet.messages?.uri or "Not a valid URI"

###
Credits
  email check regex:
  by Scott Gonzalez: http://projects.scottsplayground.com/email_address_validation/

###
