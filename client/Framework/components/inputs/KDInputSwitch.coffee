#####
# Switch Class
#####

class KDInputSwitch extends KDInputView
  constructor:(options = {})->
    options.type = "switch"
    super options
    @setPartial "<input class='checkbox hidden no-kdinput' type='checkbox' name='#{@inputGetName()}'/>"

  setDomElement:()->
    @domElement = $ "<span class='kdinput kdinputswitch off'></span>"

  inputSetDefaultValue:(value) ->
    switch value
      when on,"on","true","yes",1 then @_inputSetDefaultValue on
      else @_inputSetDefaultValue off

  inputGetDefaultValue:()-> @inputDefaultValue

  inputGetValue:()-> @getDomElement().find("input").eq(0).is ":checked"
  inputSetValue:(value)->
    switch value
      when on   then @switchAnimateOn()
      when off  then @switchAnimateOff()
      
  _inputSetDefaultValue: (val) ->
    setTimeout =>
      val = !!val
      if val
        @inputDefaultValue = on
        @getDomElement().find("input").eq(0).attr "checked",yes
        @getDomElement().removeClass("off").addClass("on")
      else
        @inputDefaultValue = off
        @getDomElement().find("input").eq(0).attr "checked",no
        @getDomElement().removeClass("on").addClass("off")
    , 0

  switchAnimateOff:()->
    return unless @inputGetValue()
    counter = 0
    timer = setInterval ()=>
      @getDomElement().css "background-position","left -#{counter * 20}px"
      if counter is 6
        clearInterval timer
        @getDomElement().find("input").eq(0).attr "checked",no
        @getDomElement().removeClass("on").addClass("off")
        @switchStateChanged()
      counter++
    ,20
  
  switchAnimateOn:()->
    return if @inputGetValue()
    counter = 6
    timer = setInterval ()=>
      @getDomElement().css "background-position","left -#{counter * 20}px"
      if counter is 0
        clearInterval timer
        @getDomElement().find("input").eq(0).attr "checked",yes
        @getDomElement().removeClass("off").addClass("on")
        @switchStateChanged()
      counter--
    ,20

  switchStateChanged:()->
    # log "new state of #{@inputGetName()} is #{@inputGetValue()}",@inputGetCallback()?
    @inputGetCallback().call @,@inputGetValue() if @inputGetCallback()?

  mouseDown:()->
    switch @inputGetValue()
      when on   then @inputSetValue off
      when off  then @inputSetValue on
    no