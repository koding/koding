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
  constructor:(options,data)->
    options = $.extend
      callback    : noop       # a Function
      customData  : {}         # an Object of key/value pairs
    ,options
    super options,data
    @valid = null
    @setCallback options.callback
    @customData = {}
  
  childAppended:(child)->
    child.associateForm? @
    if child instanceof KDInputView
      @propagateEvent KDEventType: 'inputWasAdded', child
    super
  
  bindEvents:()->
    @getDomElement().bind "submit",(event)=>
      @handleEvent event
    super()

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

  removeCustomData:(path, item)->
    if item?
      if typeof path is "string"
        JsPath.spliceAt @customData, path, (JsPath.getAt @customData, path).indexOf(item), 1 
      else
        newData = @customData
        for place in path
          newData = newData[place]
          
        JsPath.spliceAt @customData, path, newData.indexOf(item), 1 
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
    
    @once "FormValidationFinished", =>
      if @valid
        @getCallback()?.call @, formData, event
        @emit "FormValidationPassed"
      else
        @emit "FormValidationFailed"

    inputs         = KDFormView.findChildInputs @
    validatedCount = 0
    validInputs    = []
    toBeValidated  = []
    formData       = @getCustomData() or {}
    @valid         = yes
    
    # put to be validated inputs in a queue
    inputs.forEach (input)=>
      if input.getOptions().validate
        toBeValidated.push input
      else
        # put regular input values to formdata
        formData[input.getName()] = input.getValue() if input.getName()

    toBeValidated.forEach (input)=>
      # wait for the validation result of each input
      input.once "ValidationResult", (result)=>
        validatedCount++
        validInputs.push input if result
        # check if all inputs were validated
        if toBeValidated.length is validatedCount
          # check if all inputs were valid
          if toBeValidated.length is validInputs.length
            # put valid inputs to formdata
            # formData = $.extend formData, @getCustomData()
            for inputView in toBeValidated
              formData[inputView.getName()] = inputView.getValue()
          else
            @valid = no
          # tell validation was finished
          @emit "FormValidationFinished"
      input.validate null, event

    # if no validation is required mimic as all were validated
    @emit "FormValidationFinished" if toBeValidated.length is 0