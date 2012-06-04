class KDFormView extends KDView

  findChildInputs = (parent)->

    inputs   = []
    subViews = parent.getSubViews()

    if subViews.length > 0
      subViews.forEach (subView)->
        inputs.push subView if subView instanceof KDInputView
        inputs = inputs.concat findChildInputs subView

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
    @formSetCallback options.callback
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
  
  reset:=>
    @$()[0].reset()
  
  submit:(event)=>

    if event
      event.stopPropagation()
      event.preventDefault()
    
    inputs      = findChildInputs @
    validInputs = []
    inputCount  = 0

    inputs.forEach (input)=>
      if input.getOptions().validate
        input.once "ValidationResult", (result)=>
          inputCount++
          validInputs.push input if result
          if inputs.length is inputCount
            if inputs.length is validInputs.length
              @valid = yes
              formData = $.extend {}, @getCustomData()
              formData[inputView.inputName] = inputView.getValue() for inputView in inputs
              @formGetCallback()?.call @, formData, event
              @emit "FormValidationPassed"
            else
              @valid = no
              @emit "FormValidationFailed"
        input.validate null, event

  focusFirstElement:->
    @$("input,select,button,textarea").first().trigger "focus"
    
    
  formSetCallback:(callback)-> @formCallback = callback

  formGetCallback:()-> @formCallback
  
