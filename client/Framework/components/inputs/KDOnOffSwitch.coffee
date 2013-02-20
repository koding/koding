#####
# On Off Switch Class (Old KDRySwitch)
#####

class KDOnOffSwitch extends KDInputView
  constructor:(options = {}, data)->

    options.type   or= "switch"       # mandatory
    options.size   or= "small"        # a String tiny/small/big
    options.labels or= ["ON", "OFF"]

    super options, data

    @setClass options.size
    @setPartial "<input class='checkbox hidden no-kdinput' type='checkbox' name='#{@getName()}'/>"

  setDomElement:(cssClass)->
    {title, labels, name} = @getOptions()
    @inputName = name
    title or= ""

    @domElement = $ """
      <div class='kdinput on-off off #{cssClass}'>
        <span>#{title}</span>
        <a href='#' class='on' title='turn on'>#{labels[0]}</a><a href='#' class='off' title='turn off'>#{labels[1]}</a>
      </div> """

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
    return if not @getValue() and wCallback
    @inputDefaultValue = off
    @getDomElement().find("input").eq(0).attr "checked",no
    @$('a.on').removeClass('active')
    @$('a.off').addClass('active')
    @switchStateChanged() if wCallback

  _setOn:(wCallback = yes)->
    return if @getValue() and wCallback
    @inputDefaultValue = on
    @getDomElement().find("input").eq(0).attr "checked",yes
    @$('a.off').removeClass('active')
    @$('a.on').addClass('active')
    @switchStateChanged() if wCallback

  switchStateChanged:()->
    # log "new state of #{@getName()} is #{@getValue()}",@getCallback()?
    @emit 'SwitchStateChanged', @getValue()
    @getCallback().call @,@getValue() if @getCallback()?

  mouseDown:(event)->
    if $(event.target).is('a.on')
      @setValue on
    else if $(event.target).is('a.off')
      @setValue off
    # no