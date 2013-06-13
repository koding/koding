#####
# Switch Class
#####

class KDInputSwitch extends KDInputView
  constructor:(options = {})->
    options.type = "switch"
    super options
    @setPartial "<input class='checkbox hidden no-kdinput' type='checkbox' name='#{@getName()}'/>"

  setDomElement:->
    @domElement = $ "<span class='kdinput kdinputswitch off'></span>"

  setDefaultValue:(value) ->
    switch value
      when on,"on","true","yes",1 then @_setDefaultValue on
      else @_setDefaultValue off

  getDefaultValue:-> @inputDefaultValue

  getValue:-> @getDomElement().find("input").eq(0).is ":checked"
  setValue:(value)->
    switch value
      when on   then @switchAnimateOn()
      when off  then @switchAnimateOff()

  _setDefaultValue: (val) ->
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

  switchAnimateOff:->
    return unless @getValue()
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

  switchAnimateOn:->
    return if @getValue()
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

  switchStateChanged:->
    # log "new state of #{@getName()} is #{@getValue()}",@getCallback()?
    @getCallback().call @,@getValue() if @getCallback()?

  mouseDown:->
    switch @getValue()
      when on   then @setValue off
      when off  then @setValue on
    no