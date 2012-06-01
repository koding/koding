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
    @setPartial "<input class='checkbox hidden no-kdinput' type='checkbox' name='#{@inputGetName()}'/>"

  setDomElement:(cssClass)->
    @domElement = $ "<div class='kdinput kdinputswitch-ry off #{cssClass}'><a href='#' class='on' title='turn on'>ON</a><a href='#' class='off' title='turn off'>OFF</a></div>"

  inputSetDefaultValue:(value) ->
    switch value
      when on,"on","true","yes",1 then @_inputSetDefaultValue on
      else @_inputSetDefaultValue off

  inputGetDefaultValue:()-> @inputDefaultValue

  inputGetValue:()-> @getDomElement().find("input").eq(0).is ":checked"
  inputSetValue:(value)->
    switch value
      when on   then @_inputSetOn()
      when off  then @_inputSetOff()
      
  _inputSetDefaultValue: (val) ->
    setTimeout =>
      val = !!val
      if val then @_inputSetOn no else @_inputSetOff no
    , 0

  _inputSetOff:(wCallback = yes)->
    @inputDefaultValue = off
    @getDomElement().find("input").eq(0).attr "checked",no
    @$('a.on').removeClass('active')
    @$('a.off').addClass('active')
    @switchStateChanged() if wCallback

  _inputSetOn:(wCallback = yes)->
    @inputDefaultValue = on
    @getDomElement().find("input").eq(0).attr "checked",yes
    @$('a.off').removeClass('active')
    @$('a.on').addClass('active')
    @switchStateChanged() if wCallback

  switchStateChanged:()->
    # log "new state of #{@inputGetName()} is #{@inputGetValue()}",@inputGetCallback()?
    @inputGetCallback().call @,@inputGetValue() if @inputGetCallback()?

  mouseDown:(event)->
    if $(event.target).is('a.on')
      @inputSetValue on
    else if $(event.target).is('a.off')
      @inputSetValue off
    # no