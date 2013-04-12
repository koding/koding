#####
# On Off Switch Class (Old KDRySwitch)
#####

class KDOnOffSwitch extends KDInputView
  constructor:(options = {}, data)->

    options.title        or= ""
    options.type         or= "switch"       # mandatory
    options.size         or= "small"        # a String tiny/small/big
    options.labels       or= ["ON", "OFF"]
    options.defaultValue  ?= off
    super options, data

    @setClass options.size
    @setPartial "<input class='checkbox hidden no-kdinput' type='checkbox' name='#{@getName()}'/>"

    @setDefaultValue options.defaultValue

  setDomElement:(cssClass)->
    {title, labels, name} = @getOptions()
    title       = "<span>#{title}</span>" if title
    @inputName  = name
    @domElement = $ """
      <div class='kdinput on-off off #{cssClass}'>
        #{title}
        <a href='#' class='on' title='turn on'>#{labels[0]}</a><a href='#' class='off' title='turn off'>#{labels[1]}</a>
      </div> """

  getValue:-> @$("input").attr("checked") is "checked"
  setValue:(value, wCallback = yes)->
    switch value
      when on   then @setOn wCallback
      when off  then @setOff wCallback

  setDefaultValue:(value) ->
    switch value
      when on,"on","true","yes",1 then @setValue on, no
      else @setValue off, no

  setOff:(wCallback = yes)->
    return if not @getValue() and wCallback

    @$("input").attr "checked", no

    @$('a.on').removeClass('active')
    @$('a.off').addClass('active')

    @switchStateChanged() if wCallback

  setOn:(wCallback = yes)->
    return if @getValue() and wCallback

    @$("input").attr "checked", yes

    @$('a.off').removeClass('active')
    @$('a.on').addClass('active')

    @switchStateChanged() if wCallback

  switchStateChanged:->
    @emit 'SwitchStateChanged', @getValue()
    @getCallback().call @, @getValue() if @getCallback()?

  mouseDown:(event)->
    if $(event.target).is('a.on')
      @setValue on
    else if $(event.target).is('a.off')
      @setValue off

class KDCheckBox extends KDInputView
  constructor:(options = {}, data)->
    options.type   or= "checkbox"       # mandatory
    options.attributes ?= {}
    options.attributes.checked ?= options.defaultValue or no
    super options, data
