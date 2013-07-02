class KDFormView extends KDView

  @findChildInputs = (parent)->

    inputs   = []
    subViews = parent.getSubViews()

    if subViews.length > 0
      subViews.forEach (subView)->
        inputs.push subView  if subView instanceof KDInputView
        inputs = inputs.concat KDFormView.findChildInputs subView

    return inputs


  ###
  INSTANCE LEVEL
  ###
  constructor:(options = {}, data)->

    options.tagName      = "form"
    options.cssClass     = KD.utils.curryCssClass "kdformview", options.cssClass
    options.callback   or= noop     # a Function
    options.customData or= {}       # an Object of key/value pairs
    options.bind       or= "submit" # a String of space separated event names

    super options,data

    @unsetClass "kdview"
    @valid = null
    @setCallback options.callback
    @customData = {}

  childAppended:(child)->
    child.associateForm? @
    @emit 'inputWasAdded', child  if child instanceof KDInputView

    super

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

  serializeFormData:(data={})->
    for inputData in @getDomElement().serializeArray()
      data[inputData.name] = inputData.value
    data
  
  # this should be removed, this overrides KDObject::getData() and serialize is not enough for data collection - SY
  getData: ->
    formData = $.extend {},@getCustomData()
    @serializeFormData formData
    formData

  getFormData: ->
    inputs   = KDFormView.findChildInputs @
    formData = @getCustomData() or {}
    inputs.forEach (input)->
      formData[input.getName()] = input.getValue()  if input.getName()
    formData

  focusFirstElement:-> KDFormView.findChildInputs(@)[0].$().trigger "focus"

  setCallback:(callback)-> @formCallback = callback

  getCallback:-> @formCallback

  reset:-> @$()[0].reset()

  submit:(event)->

    if event
      event.stopPropagation()
      event.preventDefault()

    form                = this
    inputs              = KDFormView.findChildInputs form
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
        name  = input.getName()
        value = input.getValue()
        formData[name] = value  if name

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

