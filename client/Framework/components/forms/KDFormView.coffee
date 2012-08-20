class KDFormView extends KDView

  @findChildInputs = (parent)->

    inputs   = []
    subViews = parent.getSubViews()

    if subViews.length > 0
      subViews.forEach (subView)->
        inputs.push subView if subView instanceof KDInputView
        inputs = inputs.concat KDFormView.findChildInputs subView

    return inputs
  
  ###
  INSTANCE LEVEL
  ###
  constructor:(options = {},data)->

    options.callback   or= noop       # a Function
    options.customData or= {}         # an Object of key/value pairs

    super options,data

    @valid = null
    @setCallback options.callback
    @customData = {}
    @bindEvent "submit"
  
  childAppended:(child)->
    child.associateForm? @
    if child instanceof KDInputView
      @propagateEvent KDEventType: 'inputWasAdded', child
    super
  
  handleEvent:(event)->
    # log event.type
    # thisEvent = @[event.type]? event or yes #this would be way awesomer than lines 98-103, but then we have to break camelcase convention in mouseUp, etc. names....??? worth it?
    switch event.type
      when "submit" then thisEvent = @submit event
    superResponse = super event #always needs to be called for propagation
    thisEvent = thisEvent ? superResponse #only return superResponse if local handle didn't happen
    willPropagateToDOM = thisEvent

  setDomElement:()->
    cssClass = @getOptions().cssClass ? ""
    @domElement = $ "<form class='kdformview #{cssClass}'></form>"
  
  getCustomData:(path)->
    if path
      JsPath.getAt @customData, path
    else
      @customData
    
  addCustomData:(path, value)->
    if 'string' is typeof path
      JsPath.setAt @customData, path, value
    else
      for own key, value of path
        JsPath.setAt @customData, key, value

  removeCustomData:(path)->
    path = path.split '.' if 'string' is typeof path
    [pathUntil..., last] = path 
    isArrayElement = not isNaN +last
    if isArrayElement
      JsPath.spliceAt @customData, pathUntil, last
    else
      JsPath.deleteAt @customData, path
  
  getData: ->
    formData = $.extend {},@getCustomData()

    for inputData in @getDomElement().serializeArray()
      formData[inputData.name] = inputData.value
        
    formData

  focusFirstElement:-> KDFormView.findChildInputs(@)[0].$().trigger "focus"
    
  setCallback:(callback)-> @formCallback = callback

  getCallback:()-> @formCallback
  
  reset:=> @$()[0].reset()
  
  submit:(event)=>

    if event
      event.stopPropagation()
      event.preventDefault()
    
    form                = @
    inputs              = KDFormView.findChildInputs @
    validationCount     = 0
    toBeValidatedInputs = []
    validInputs         = []
    formData            = @getCustomData() or {}

    @once "FormValidationFinished", (isValid = yes)->
      form.valid = isValid
      if isValid
        form.getCallback()?.call form, formData, event
        form.emit "FormValidationPassed"
      else
        form.emit "FormValidationFailed"

    # put to be validated inputs in a queue
    inputs.forEach (input)->
      if input.getOptions().validate
        toBeValidatedInputs.push input
      else
        # put regular input values to formdata
        formData[input.getName()] = input.getValue() if input.getName()

    toBeValidatedInputs.forEach (inputToBeValidated)->
      # wait for the validation result of each input
      do ->
        inputToBeValidated.once "ValidationResult", (result)->
          validationCount++
          validInputs.push inputToBeValidated if result
          # check if all inputs were validated
          if toBeValidatedInputs.length is validationCount
            # check if all inputs were valid
            if validInputs.length is toBeValidatedInputs.length
              # put valid inputs to formdata
              formData[input.getName()] = input.getValue() for input in validInputs                
            else
              valid = no
            # tell validation was finished
            form.emit "FormValidationFinished", valid
      inputToBeValidated.validate null, event

    # if no validation is required mimic as all were validated
    form.emit "FormValidationFinished" if toBeValidatedInputs.length is 0      

