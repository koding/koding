#####
# Ryan Switch Class
#####

class KDRySwitch extends KDInputView
  constructor:(options)->
    options = $.extend
      type : "switch"       # mandatory
      size : "small"        # a String "small" or "big"
    ,options  
    super options
    @setClass options.size
    @setPartial "<input class='checkbox hidden no-kdinput' type='checkbox' name='#{@getName()}'/>"

  setDomElement:(cssClass)->
    @domElement = $ "<div class='kdinput kdinputswitch-ry off #{cssClass}'><a href='#' class='on' title='turn on'>ON</a><a href='#' class='off' title='turn off'>OFF</a></div>"

  setDefaultValue:(value) ->
    switch value
      when on,"on","true","yes",1 then @_setDefaultValue on
      else @_setDefaultValue off

  getDefaultValue:()-> @inputDefaultValue

  getValue:()-> @getDomElement().find("input").eq(0).is ":checked"
  setValue:(value)->
    switch value
      when on   then @_setOn()
      when off  then @_setOff()
      
  _setDefaultValue: (val) ->
    setTimeout =>
      val = !!val
      if val then @_setOn no else @_setOff no
    , 0

  _setOff:(wCallback = yes)->
    @inputDefaultValue = off
    @getDomElement().find("input").eq(0).attr "checked",no
    @$('a.on').removeClass('active')
    @$('a.off').addClass('active')
    @switchStateChanged() if wCallback

  _setOn:(wCallback = yes)->
    @inputDefaultValue = on
    @getDomElement().find("input").eq(0).attr "checked",yes
    @$('a.off').removeClass('active')
    @$('a.on').addClass('active')
    @switchStateChanged() if wCallback

  switchStateChanged:()->
    # log "new state of #{@getName()} is #{@getValue()}",@getCallback()?
    @getCallback().call @,@getValue() if @getCallback()?

  mouseDown:(event)->
    if $(event.target).is('a.on')
      @setValue on
    else if $(event.target).is('a.off')
      @setValue off
    # no