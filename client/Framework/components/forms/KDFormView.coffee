class KDFormView extends KDView
  
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
    inputArray = @getDomElement().find "input,select,button,textarea"
    inputItemInstances = []
    for inputItem in inputArray
      inputItem = $(inputItem).closest(".kdinput")[0] if $(inputItem).hasClass "no-kdinput"
      kdview = KD.getKDViewInstanceFromDomElement inputItem
      inputItemInstances.push kdview if kdview
    # SIMPLIFY THIS
    validators = for inputItemInstance in inputItemInstances
      f = (validator) ->
        (callback) ->
          if validator?
            validator.validateAsync (data) =>
              callback null, data
          else
            callback null, yes # inputs which not contain validator are valid
      f inputItemInstance.inputValidator

    async.parallel validators, (err, resultSet) =>

      resultSet = for results in resultSet
        results.join '.' if $.isArray results
      resultSet = resultSet.join '|'
    
      if resultSet.search(/false/) < 0
        # log "form submit passed validation!"
        callback = @formGetCallback()
        if callback?
          # log "there is callback",@getDomElement().serializeArray(),@
          formData = $.extend {},@getCustomData()
          for inputData in @getDomElement().serializeArray()
            formData[inputData.name] = inputData.value

          callback.call @, formData,event
        @valid = yes
      else
        warn "form submit failed validation!"
        @propagateEvent KDEventType : "ValidationFailed"
        @valid = no

    return no #propagations leads to window refresh

  focusFirstElement:->
    @$("input,select,button,textarea").first().trigger "focus"
    
    
  formSetCallback:(callback)->
    @formCallback = callback
  formGetCallback:()-> @formCallback
  
