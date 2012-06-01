class KDInputValidator extends KDObject
  constructor:(ruleSet,aKDViewInstance)->
    super()
    @valid = no
    @ruleSet = ruleSet
    @boundKDInputInstance = aKDViewInstance
    @initValidation ruleSet,aKDViewInstance
  
  initValidation:()->
    @ruleChain   = @createRuleChain @ruleSet
    for rule in @ruleChain
      if @ruleSet.event?
        @listenTo
          KDEventTypes       : @ruleSet.event
          listenedToInstance : @boundKDInputInstance
          callback           : @["rule#{rule.capitalize()}"]
      

  validate:(pubInst = @boundKDInputInstance, event)->
    validators = for rule in @ruleChain
      @["rule#{rule.capitalize()}"] @boundKDInputInstance, event

  validateAsync:(callback)->

    # validators is array of rule's functions, which calls parellel by async lib
    validators = for rule in @ruleChain
      f = (rule, boundKDInputInstance) =>
        # now here avaliable rule, boundKDInputInstance variables
        (callback)=> @["rule#{rule.capitalize()}"] boundKDInputInstance, { callback : (valid) => callback null, !!valid }
      f rule, @boundKDInputInstance

    async.parallel validators, (err, results)->
      res = for r in results
        !!r # replace null -> false
      callback res

  createRuleChain:(ruleSet)-> 
    if typeof ruleSet.rules is "object"
      chain = (rule for rule,value of ruleSet.rules)
    else
      chain = [ruleSet.rules]
  
  ruleRequired:(publishingInstance,event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    ruleSet = publishingInstance.getOptions().validate
    doesValidate = (value.length > 0)
    if doesValidate
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "Field is required!"
      errorMessage = ruleSet.messages.required if ruleSet.messages?.required
      publishingInstance.inputSetValidationResult no,errorMessage
    if callback? then callback @valid else @valid  


  ruleEmail:(publishingInstance,event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    ruleSet = publishingInstance.getOptions().validate
    doesValidate = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value)
    if doesValidate
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "Please enter a valid email address!"
      errorMessage = ruleSet.messages.email if ruleSet.messages?.email
      publishingInstance.inputSetValidationResult no,errorMessage
    #console.log 'ruleEmail', callback  
    if callback? then callback @valid else @valid  

  ruleMinLength:(publishingInstance,event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    return warn "minLength should be specified at KDInputView ruleset" unless publishingInstance.getOptions().validate?.rules?.minLength?
    ruleSet = publishingInstance.getOptions().validate
    minLength = ruleSet.rules.minLength

    if value.length >= minLength 
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "Please enter a value that includes more than #{minLength} characters!"
      errorMessage = ruleSet.messages.minLength if ruleSet.messages?.minLength
      publishingInstance.inputSetValidationResult no,errorMessage
    if callback? then callback @valid else @valid  

  ruleMaxLength:(publishingInstance,event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    return warn "maxLength should be specified at KDInputView ruleset" unless publishingInstance.getOptions().validate?.rules?.maxLength?
    ruleSet = publishingInstance.getOptions().validate
    maxLength = ruleSet.rules.maxLength

    if value.length <= maxLength
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "Please enter a value that includes less than #{maxLength} characters!"
      errorMessage = ruleSet.messages.maxLength if ruleSet.messages?.maxLength?
      publishingInstance.inputSetValidationResult no,errorMessage
    if callback? then callback @valid else @valid  

  ruleRangeLength:(publishingInstance,event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    return warn "rangeLength should be specified at KDInputView ruleset" unless publishingInstance.getOptions().validate?.rules?.rangeLength?
    ruleSet = publishingInstance.getOptions().validate
    rangeLength = ruleSet.rules.rangeLength

    if value.length <= rangeLength[1] and value.length >= rangeLength[0]
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "Please enter a value that includes more than #{rangeLength[0]} and less than #{rangeLength[0]} characters!"
      errorMessage = ruleSet.messages.rangeLength if ruleSet.messages?.rangeLength
      publishingInstance.inputSetValidationResult no,errorMessage
    if callback? then callback @valid else @valid
  
  ruleUserProvidedFn:(publishingInstance,event)->
    {callback} = event
    ruleSet = publishingInstance.getOptions().validate
    fn = ruleSet.rules.userProvidedFn
    doesValidate = fn.apply publishingInstance, arguments
    
    if doesValidate
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "Custom validation failed!"
      errorMessage = ruleSet.messages.userProvidedFn if ruleSet.messages?.userProvidedFn
      publishingInstance.inputSetValidationResult no,errorMessage

    if callback? then callback @valid else @valid

  ruleMatch:(publishingInstance,event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    return warn "A KDInputView instance should be specified at KDInputView ruleset" unless publishingInstance.getOptions().validate?.rules?.match?
    ruleSet = publishingInstance.getOptions().validate
    matchingInstance = ruleSet.rules.match
    matchingInstanceValue = $.trim matchingInstance.inputGetValue()

    if value is matchingInstanceValue
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "Values do not match!"
      errorMessage = ruleSet.messages.match if ruleSet.messages?.match
      publishingInstance.inputSetValidationResult no,errorMessage
    if callback? then callback @valid else @valid

  ruleCreditCard:(publishingInstance,event)->
    {callback} = event
    ###
      Visa: ^4[0-9]{12}(?:[0-9]{3})?$ All Visa card numbers start with a 4. New cards have 16 digits. Old cards have 13.
      MasterCard: ^5[1-5][0-9]{14}$ All MasterCard numbers start with the numbers 51 through 55. All have 16 digits.
      American Express: ^3[47][0-9]{13}$ American Express card numbers start with 34 or 37 and have 15 digits.
      Diners Club: ^3(?:0[0-5]|[68][0-9])[0-9]{11}$ Diners Club card numbers begin with 300 through 305, 36 or 38. All have 14 digits. There are Diners Club cards that begin with 5 and have 16 digits. These are a joint venture between Diners Club and MasterCard, and should be processed like a MasterCard.
      Discover: ^6(?:011|5[0-9]{2})[0-9]{12}$ Discover card numbers begin with 6011 or 65. All have 16 digits.
      JCB: ^(?:2131|1800|35\d{3})\d{11}$ JCB cards beginning with 2131 or 1800 have 15 digits. JCB cards beginning with 35 have 16 digits.
    ###
    value = $.trim publishingInstance.inputGetValue()
    value = value.replace /-/g,""
    value = value.replace /\s/g,""
    log value
    ruleSet = publishingInstance.getOptions().validate
    doesValidate = /(^4[0-9]{12}(?:[0-9]{3})?$)|(^5[1-5][0-9]{14}$)|(^3[47][0-9]{13}$)|(^3(?:0[0-5]|[68][0-9])[0-9]{11}$)|(^6(?:011|5[0-9]{2})[0-9]{12}$)|(^(?:2131|1800|35\d{3})\d{11}$)/.test(value)
    if doesValidate
      @valid = yes
      publishingInstance.inputSetValidationResult yes

      type = if /^4[0-9]{12}(?:[0-9]{3})?$/.test(value)       then "Visa"
      else if /^5[1-5][0-9]{14}$/.test(value)                 then "MasterCard"
      else if /^3[47][0-9]{13}$/.test(value)                  then "Amex"
      else if /^3(?:0[0-5]|[68][0-9])[0-9]{11}$/.test(value)  then "Diners"
      else if /^6(?:011|5[0-9]{2})[0-9]{12}$/.test(value)     then "Discover"
      else if /^(?:2131|1800|35\d{3})\d{11}$/.test(value)     then "JCB"
      else no
      publishingInstance.handleEvent type : "ValidatorHasToSay", creditCardType : type
      
    else
      @valid = no
      errorMessage = "Please enter a valid credit card number!"
      errorMessage = ruleSet.messages.creditCard if ruleSet.messages?.creditCard
      publishingInstance.inputSetValidationResult no,errorMessage
    @valid
  
  ruleJSON:(publishingInstance,event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    ruleSet = publishingInstance.getOptions().validate

    doesValidate = yes
    try
      JSON.parse value if value
    catch err
      doesValidate = no
      error err,doesValidate

    if doesValidate
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid = no
      errorMessage = "a valid JSON is required!"
      errorMessage = ruleSet.messages.JSON if ruleSet.messages?.JSON
      publishingInstance.inputSetValidationResult no,errorMessage
    if callback? then callback @valid else @valid  
  
  ruleRegExp:(publishingInstance, event)->
    {callback} = event
    value = $.trim publishingInstance.inputGetValue()
    ruleSet = publishingInstance.getOptions().validate
    doesValidate = ruleSet.regExp.test(value)
    if doesValidate
      @valid = yes
      publishingInstance.inputSetValidationResult yes
    else
      @valid       = no
      errorMessage = if ruleSet.messages?.regExp then ruleSet.messages.regExp else "Provided regular expression didn't match!"
      publishingInstance.inputSetValidationResult no,errorMessage
    if callback? then callback @valid else @valid  


###
Inspired by
 jQuery Validation Plugin 1.8.0
 http://bassistance.de/jquery-plugins/jquery-plugin-validation/
 Copyright (c) 2006 - 2011 Jörn Zaefferer

Credits
  email check regex:
  by Scott Gonzalez: http://projects.scottsplayground.com/email_address_validation/

###
