class KDInputView extends KDView

  constructor:(o = {}, data)->

    o.type                    or= "text"        # a String of one of input types "text","password","select", etc...
    o.name                    or= ""            # a String
    o.label                   or= null          # a KDLabelView instance
    o.cssClass                or= ""            # a String
    o.callback                or= null          # a Function
    o.defaultValue             ?= ""            # a String or a Boolean value depending on type
    o.placeholder             or= ""            # a String
    o.disabled                 ?= no            # a Boolean value
    # o.readonly               ?= no            # a Boolean value
    o.selectOptions           or= null          # an Array of Strings
    o.validate                or= null          # an Object of Validation options see KDInputValidator for details
    o.validationNotifications  ?= yes
    o.hint                    or= null          # a String of HTML
    o.autogrow                 ?= no            # a Boolean
    o.enableTabKey             ?= no            # a Boolean # NOT YET READY needs some work
    o.bind                    or= ""            # a String of event names
    o.forceCase               or= null          # a String of either "lowercase" or "uppercase"

    o.bind += " blur change focus"

    @setType o.type

    super o, data

    options = @getOptions()

    @inputValidationNotifications = {}
    @valid = yes
    @inputCallback = null
    @setLabel()
    @setCallback()
    @setDefaultValue options.defaultValue
    @setPlaceHolder options.placeholder
    @makeDisabled() if options.disabled
    if options.selectOptions? and 'function' isnt typeof options.selectOptions
      @setSelectOptions options.selectOptions
    @setAutoGrow() if options.autogrow
    @enableTabKey() if options.enableTabKey
    @setCase options.forceCase if options.forceCase

    if options.validate?
      @setValidation options.validate
      @on "ValidationError", @bound "giveValidationFeedback"
      @on "ValidationPassed", @bound "giveValidationFeedback"
      @on "focus", @bound "clearValidationFeedback"

    if options.type is "select" and options.selectOptions
      @on "viewAppended", =>
        o = @getOptions()
        if 'function' is typeof o.selectOptions
          kallback = @bound "setSelectOptions"
          o.selectOptions.call @, kallback
        else unless o.selectOptions.length
          @setValue o.selectOptions[Object.keys(o.selectOptions)[0]][0].value unless o.defaultValue
        else
          @setValue o.selectOptions[0].value unless o.defaultValue

  setDomElement:(cssClass = "")->
    @inputName = @options.name
    name = "name='#{@options.name}'"
    @domElement = switch @getType()
      when "text"     then $ "<input #{name} type='text' class='kdinput text #{cssClass}'/>"
      when "password" then $ "<input #{name} type='password' class='kdinput text #{cssClass}'/>"
      when "hidden"   then $ "<input #{name} type='hidden' class='kdinput hidden #{cssClass}'/>"
      when "checkbox" then $ "<input #{name} type='checkbox' class='kdinput checkbox #{cssClass}'/>"
      when "textarea" then $ "<textarea #{name} class='kdinput text #{cssClass}'></textarea>"
      when "select"   then $ "<select #{name} class='kdinput select #{cssClass}'/>"
      when "range"    then $ "<input #{name} type='range' class='kdinput range #{cssClass}'/>"
      else                 $ "<input #{name} type='#{@getType()}' class='kdinput #{@getType()} #{cssClass}'/>"

  setLabel:(label = @options.label)->

    return no unless @options.label?
    @inputLabel = label
    @inputLabel.getDomElement().attr "for",@getName()
    @inputLabel.getDomElement().bind "click",()=>
      @getDomElement().trigger "focus"
      @getDomElement().trigger "click"

  getLabel:()-> @inputLabel

  setCallback:()-> @inputCallback = @options.callback

  getCallback:()-> @inputCallback

  setType:(type = "text")-> @inputType = type

  getType:()-> @inputType

  getName:()-> @inputName

  setFocus:()->
    (@getSingleton "windowController").setKeyView @
    @$().trigger "focus"

  setBlur:()->
    (@getSingleton "windowController").setKeyView null
    @$().trigger "blur"

  setSelectOptions:(options)->
    unless options.length
      for optGroup, subOptions of options
        $optGroup = $ "<optgroup label='#{optGroup}'/>"
        @$().append $optGroup
        for option in subOptions
          $optGroup.append "<option value='#{option.value}'>#{option.title}</option>"
    else if options.length
      for option in options
        @$().append "<option value='#{option.value}'>#{option.title}</option>"
    else
      warn "no valid options specified for the input:", @

    @$().val @getDefaultValue()

  setDefaultValue:(value) ->
    if @getOption("type") is "checkbox"
      @getDomElement().attr checked : value
    else
      @getDomElement().val value if value isnt ""

    @inputDefaultValue = value

  getDefaultValue:()->
    @inputDefaultValue

  setPlaceHolder:(value)->
    if @$().is("input") or @$().is("textarea")
      @$().attr "placeholder",value
      @options.placeholder = value

  makeDisabled:()->
    @getDomElement().attr "disabled","disabled"

  makeEnabled:()->
    @getDomElement().removeAttr "disabled"

  getValue:()->
    if @getOption("type") is "checkbox"
      value = @$().is ':checked'
    else
      value = @getDomElement().val()
      {forceCase} = @getOptions()
      if forceCase
        value = if /uppercase/i.test forceCase
          value.toUpperCase()
        else
          value.toLowerCase()

    return value

  setValue:(value)->
    if @getOption("type") is "checkbox"
      @getDomElement().attr checked : value
    else @getDomElement().val(value) if value?

  _prevVal = null

  setCase:(forceCase)->
    cb = =>
      val = @getValue()
      return if val is _prevVal
      @setValue _prevVal = val

    @on "keyup", cb.bind this
    @on "blur",  cb.bind this

  setValidation:(ruleSet)->

    @valid                 = no
    @currentRuleset        = ruleSet
    @validationCallbacks or= {}
    @createRuleChain ruleSet

    for oldEventName, oldCallbacks of @validationCallbacks
      for oldCallback in oldCallbacks
        @off oldEventName, oldCallback

    @ruleChain.forEach (rule)=>
      eventName = \
        if ruleSet.events
          if ruleSet.events[rule] then ruleSet.events[rule]
          else if ruleSet.event   then ruleSet.event
        else if ruleSet.event     then ruleSet.event

      if eventName
        @validationCallbacks[eventName] or= []
        @validationCallbacks[eventName].push cb = (event)=>
          @validate rule, event  if rule in @ruleChain

        @on eventName, cb


  validate:(rule, event = {})->

    @ruleChain          or= []
    @validationResults  or= {}
    rulesToBeValidated    = if rule then [rule] else @ruleChain
    ruleSet               = @currentRuleset or @getOptions().validate

    if @ruleChain.length > 0
      rulesToBeValidated.forEach (rule)=>
        if KDInputValidator["rule#{rule.capitalize()}"]?
          result = KDInputValidator["rule#{rule.capitalize()}"] @, event
          @setValidationResult rule, result
        else if "function" is typeof ruleSet.rules[rule]
          ruleSet.rules[rule] @, event
    else
      @valid = yes

    allClear = yes
    for result, errMsg of @validationResults
      if errMsg then allClear = no

    if allClear
      @emit "ValidationPassed"
      @emit "ValidationResult", yes
      @valid = yes
    else
      @emit "ValidationResult", no


  createRuleChain:(ruleSet)->

    {rules} = ruleSet
    @validationResults or= {}
    @ruleChain = if typeof rules is "object" then (rule for rule,value of rules) else [rules]
    for rule in @ruleChain
      @validationResults[rule] = null

  setValidationResult:(rule, err, showNotification=on)->
    if err
      @validationResults[rule] = err
      @showValidationError err if @getOptions().validationNotifications and showNotification
      @emit "ValidationError", err
      @valid = no
    else
      @validationResults[rule] = null

  showValidationError:(message)->

    if @inputValidationNotifications[message]
      @inputValidationNotifications[message].destroy()

    @inputValidationNotifications[message] = notice = new KDNotificationView
      title     : message
      type      : 'growl'
      cssClass  : 'mini'
      duration  : 2500

    notice.on "KDObjectWillBeDestroyed", =>
      message = notice.getOptions().title
      delete @inputValidationNotifications[message]

  clearValidationFeedback:->

    @unsetClass "validation-error validation-passed"
    @emit "ValidationFeedbackCleared"

  giveValidationFeedback:(err)->

    if err
      @setClass "validation-error"
    else
      @setClass "validation-passed"
      @unsetClass "validation-error"


  setCaretPosition:(pos)-> @selectRange pos, pos

  getCaretPosition:->
    el = @$()[0]
    # modern
    if el.selectionStart
      return el.selectionStart
    # ie
    else if document.selection
      el.focus()
      r = document.selection.createRange()
      return 0 unless r
      re = el.createTextRange()
      rc = re.duplicate()
      re.moveToBookmark r.getBookmark()
      rc.setEndPoint 'EndToStart', re

      return rc.text.length
    return 0

  selectAll:-> @getDomElement().select()

  selectRange:(selectionStart, selectionEnd)->

    input = @$()[0]

    if input.setSelectionRange
      input.focus()
      input.setSelectionRange selectionStart, selectionEnd

    else if input.createTextRange
      range = input.createTextRange()
      range.collapse yes
      range.moveEnd 'character', selectionEnd
      range.moveStart 'character', selectionStart
      range.select()

  setAutoGrow:->

    @setClass "autogrow"
    $growCalculator = $ "<div/>", class : "invisible"

    @on "focus", =>
      @utils.defer =>
        $growCalculator.appendTo 'body'
        $growCalculator.css
          height        : "auto"
          "z-index"     : 100000
          width         : @$().width()
          padding       : @$().css('padding')
          "word-break"  : @$().css('word-break')
          "font-size"   : @$().css('font-size')
          "line-height" : @$().css('line-height')

    @on "blur", =>
      $growCalculator.detach()
      @$()[0].style.height = "none" # hack to set to initial

    @on "keyup", =>
      $growCalculator.text @getValue()
      height    = $growCalculator.height()
      if @$().css('box-sizing') is "border-box"
        padding = parseInt(@$().css('padding-top'),10) + parseInt(@$().css('padding-bottom'),10)
        border  = parseInt(@$().css('border-top-width'),10) + parseInt(@$().css('border-bottom-width'),10)
        height  = height + border + padding

      @setHeight height

  enableTabKey:-> @inputTabKeyEnabled = yes

  disableTabKey:-> @inputTabKeyEnabled = no

  change:->

  keyUp:-> yes

  keyDown:(event)->

    @checkTabKey event if @inputTabKeyEnabled
    yes

  focus:->

    @setKeyView @
    yes

  blur:->
    # this messes up things
    # if you switch between inputs on focus next input sets the keyview to itself
    # and this fires right afterwards and reverts it back to blurred one

    # hopefully fixed

    @getSingleton("windowController").revertKeyView @
    yes

  mouseDown:->

    @setFocus()
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



