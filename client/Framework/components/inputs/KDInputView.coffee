#####
# Base Class KDInputView
#####

class KDInputView extends KDView

  constructor:(options = {},data)->
    options = $.extend
      type          : "text"        # a String of one of input types "text","password","select", etc...
      name          : ""            # a String
      label         : null          # a KDLabelView instance
      cssClass      : ""            # a String
      callback      : null          # a Function
      defaultValue  : ""            # a String or a Boolean value depending on type
      placeholder   : ""            # a String
      disabled      : no            # a Boolean value
      # readonly      : no            # a Boolean value                                                    
      selectOptions : null          # an Array of Strings
      validate      : null          # an Object of Validation options see KDInputValidator for details
      hint          : null          # a String of HTML
      autogrow      : no            # a Boolean
      enableTabKey  : no            # a Boolean # NOT YET READY needs some work
      bind          : ""            # a String of event names
      forceCase     : null          # a String of either "lowercase" or "uppercase"
      # new HTML5 input properties, choose wisely. chart can be found in this link http://d.pr/vvn4
      attributes            :
        autocomplete        : null
        dirname             : null
        list                : null
        maxlength           : null
        pattern             : null
        readonly            : null
        required            : null
        size                : null
        list                : null
        selectionStart      : null
        selectionEnd        : null
        selectionDirection  : null
        multiple            : null # > for email only
        min                 : null # > range, number only
        max                 : null # > range, number only
        step                : null # > range, number only
        valueAsNumber       : null # > number only

    ,options

    options.bind += " blur change focus"

    @inputSetType options.type

    super options,data
    @inputValidationNotifications = {}
    @inputValidationPassed = yes
    @inputCallback = null
    @inputSetLabel()
    @inputSetCallback()
    @inputSetDefaultValue options.defaultValue
    @inputSetPlaceHolder options.placeholder
    @inputMakeDisabled() if options.disabled
    @inputSetSelectOptions options.selectOptions if options.selectOptions?
    @inputSetAutoGrow() if options.autogrow
    @inputEnableTabKey() if options.enableTabKey
    @inputSetCase options.forceCase if options.forceCase
    @inputBindSubmit()
    if options.validate?
      @inputSetValidation options.validate
      @on "ValidationError",@inputSetValidationErrorStyle
      @on "ValidationPassed",@inputClearValidationErrorStyle
      @listenTo KDEventTypes : "blur", listenedToInstance : @, callback : @inputClearValidationErrorStyle

    @listenTo 
      KDEventTypes       : "viewAppended"
      listenedToInstance : @
      callback           : =>
        o = @getOptions()
        if o.type is "select" and o.selectOptions
          @inputSetValue o.selectOptions[0].value unless o.defaultValue

    # wait for a fix for positioning the hint
    # if options.hint?
    #   @listenTo
    #     KDEventTypes        : [ eventType : "viewAppended"]
    #     listenedToInstance  : @
    #     callback            : ()-> @inputBindHint options.hint

  setDomElement:(cssClass = "")->
    @inputName = @options.name
    name = "name='#{@options.name}'"
    @domElement = switch @inputGetType()
      when "text"     then $ "<input #{name} type='text' class='kdinput text #{cssClass}'/>"
      when "password" then $ "<input #{name} type='password' class='kdinput text #{cssClass}'/>"
      when "hidden"   then $ "<input #{name} type='hidden' class='kdinput hidden #{cssClass}'/>"
      when "checkbox" then $ "<input #{name} type='checkbox' class='kdinput checkbox #{cssClass}'/>"
      when "textarea" then $ "<textarea #{name} class='kdinput text #{cssClass}'></textarea>"
      when "select"   then $ "<select #{name} class='kdinput select #{cssClass}'/>"
      when "range"    then $ "<input #{name} type='range' class='kdinput range #{cssClass}'/>"
      else                 $ "<input #{name} type='#{@inputGetType()}' class='kdinput #{@inputGetType()} #{cssClass}'/>"

  destroy:->
    @inputValidator?.destroy()
    super

  inputSetLabel:(label = @options.label)->
    return no unless @options.label?
    @inputLabel = label
    @inputLabel.getDomElement().attr "for",@inputGetName()
    @inputLabel.getDomElement().bind "click",()=> 
      @getDomElement().trigger "focus"
      @getDomElement().trigger "click"

  inputGetLabel:()-> 
    @inputLabel

  inputSetCallback:()->
    @inputCallback = @options.callback

  inputGetCallback:()-> 
    @inputCallback

  inputSetType:(type = "text")->
    @inputType = type

  inputGetType:()-> 
    @inputType

  inputGetName:()->
    @inputName
  
  inputSetFocus:()->
    (@getSingleton "windowController").setKeyView @
    @$().trigger "focus"
  
  inputSetSelectOptions:(options)->
    for option in options
      @$().append "<option value='#{option.value}'>#{option.title}</option>"
    @$().val @inputGetDefaultValue()

  inputSetDefaultValue:(value) ->
    @getDomElement().val value if value isnt ""
    @inputDefaultValue = value

  inputGetDefaultValue:()->
    @inputDefaultValue
  
  inputSetPlaceHolder:(value)->
    if @$().is("input") or @$().is("textarea")
      @$().attr "placeholder",value
      @options.placeholder = value

  inputMakeDisabled:()->
    @getDomElement().attr "disabled","disabled"

  inputMakeEnabled:()->
    @getDomElement().removeAttr "disabled"

  inputGetValue:()-> 
    value = @getDomElement().val()
    {forceCase} = @getOptions()
    if forceCase
      value = if /uppercase/i.test forceCase
        value.toUpperCase()
      else
        value.toLowerCase()

    return value
    
  inputSetValue:(value)->
    @getDomElement().val(value) if value?

  inputSetCase:(forceCase)->
    @setClass forceCase
    

  inputBindSubmit:()->
    # @getDomElement().bind "click",@doOnSubmit
  
  inputBindHint:(hint)->
    # $hint = $ "<span class='kdinputhint'>#{hint}</span>"
    # # _bind = ()=>
    # log "something",@$().position()
    # @$().wrap '<div class="kdinputwrapper" />' unless @$().parent().is ".kdinputwrapper"
    # @$().after $hint
    #   # @$().keyup ()=>
    #   #   if @inputGetValue() is "" then do _showHint else do _hideHint
    #   # _showHint = ()=> $hint.show()
    #   # _hideHint = ()=> $hint.hide()
    # 
    # $hint
  
  inputDoOnSubmit:()=>
    if @inputGetCallback()?
      @inputGetCallback().call()
    else
      log "i'm an input, but have nothing to do"
  
  inputTriggerClick:()->
    @inputDoOnSubmit()
  
  inputSetValidation:(ruleSet)->
    @inputValidationPassed = no
    @inputValidator = new KDInputValidator ruleSet,@
  
  inputSetValidationResult:(didPass,message)->
    if didPass
      @inputValidationPassed = yes
      @inputClearValidationErrorStyle()
      @emit "ValidationPassed",@inputValidationMessage
    else
      @inputValidationPassed = no
      @inputValidationMessage = message
      @inputShowValidationError message
      @emit "ValidationError",message

  inputShowValidationError:(message)->
    if @inputValidationNotifications[message]
      @inputValidationNotifications[message].destroy()

    @inputValidationNotifications[message] = notice = new KDNotificationView
      title     : message
      type      : 'growl'
      cssClass  : 'mini'
      duration  : 2500

    @listenTo
      KDEventTypes       : "KDObjectWillBeDestroyed"
      listenedToInstance : notice
      callback           : =>
        message = notice.getOptions().title
        delete @inputValidationNotifications[message]

  inputSetValidationErrorStyle:()=>
    @setClass "validation-error"

  inputClearValidationErrorStyle:()=>
    @unsetClass "validation-error"
    
  inputSelectAll:()->
    @getDomElement().select()

  inputSetAutoGrow:->
    @$().autogrow()
  
  inputEnableTabKey:->
    @inputTabKeyEnabled = yes
  inputDisableTabKey:->
    @inputTabKeyEnabled = no
  
  # bindEvents:()->
  #   @getDomElement().bind "blur change focus",(event)=>
  #     @handleEvent event
  #   super
  
  # handleEvent:(event)->
  #   # log event.type
  #   # thisEvent = @[event.type]? event or yes #this would be way awesomer than lines 98-103, but then we have to break camelcase convention in mouseUp, etc. names....??? worth it?
  #   thisEvent = switch event.type
  #     when "blur" then @blur event
  #     when "change" then @change event
  #     when "focus" then @focus event
  #     # when "keyup" then @keyUp event
  #     # when "keydown" then @keyDown event
  #   superResponse = super event #always needs to be called for propagation
  #   thisEvent = thisEvent ? superResponse #only return superResponse if local handle didn't happen
  #   willPropagateToDOM = thisEvent
  
  change:->

  keyUp:->

  keyDown:(event)->

    @checkTabKey event if @inputTabKeyEnabled
      
    
  focus:->

    @getSingleton("windowController").setKeyView @


  blur:->

    @getSingleton("windowController").revertKeyView()
  
  mouseDown:=>
    # log "input mouse down"
    @inputSetFocus()
    #WHY NO?
    #NO because if it propagates, other stuff might become keyview
    no
  

  
  checkTabKey:(event)->
    tab = "  "
    tabLength = tab.length
    t   = event.target
    ss  = t.selectionStart
    se  = t.selectionEnd

    # // Tab key - insert tab expansion
    if event.which is 9
      event.preventDefault()
      # // Special case of multi line selection
      if ss isnt se and t.value.slice(ss,se).indexOf("n") isnt -1
        # // In case selection was not of entire lines (e.g. selection begins in the middle of a line)
        # // we ought to tab at the beginning as well as at the start of every following line.
        pre     = t.value.slice(0,ss)
        sel     = t.value.slice(ss,se).replace(/n/g,"n"+tab)
        post    = t.value.slice(se,t.value.length)
        t.value = pre.concat(tab).concat(sel).concat(post)

        t.selectionStart = ss + tab.length
        t.selectionEnd   = se + tab.length

      # // "Normal" case (no selection or selection on one line only)
      else
        t.value = t.value.slice(0,ss).concat(tab).concat(t.value.slice(ss,t.value.length))
        if ss is se
          t.selectionStart = t.selectionEnd = ss + tab.length
        else
          t.selectionStart = ss + tab.length
          t.selectionEnd   = se + tab.length

      # // Backspace key - delete preceding tab expansion, if exists
    else if event.which is 8 and t.value.slice(ss - tabLength,ss) is tab
      event.preventDefault()

      t.value = t.value.slice(0,ss - tabLength).concat(t.value.slice(ss,t.value.length))
      t.selectionStart = t.selectionEnd = ss - tab.length

    # // Delete key - delete following tab expansion, if exists
    else if event.which is 46 and t.value.slice(se,se + tabLength) is tab
      event.preventDefault()

      t.value = t.value.slice(0,ss).concat(t.value.slice(ss + tabLength,t.value.length))
      t.selectionStart = t.selectionEnd = ss

    # // Left/right arrow keys - move across the tab in one go
    else if event.which is 37 && t.value.slice(ss - tabLength,ss) is tab
      event.preventDefault()
      t.selectionStart = t.selectionEnd = ss - tabLength

    else if event.which is 39 and t.value.slice(ss,ss + tabLength) is tab
      event.preventDefault()
      t.selectionStart = t.selectionEnd = ss + tabLength



  