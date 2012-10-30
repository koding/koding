class KDInputRadioGroup extends KDInputView
  constructor:(options)->
    @setType "radio"
    super options

  setDomElement:()->
    options = @getOptions()
    @domElement = $ "<fieldset class='radiogroup kdinput'></fieldset>"
    for radio,i in options.radios
      $div = $ "<div/>"
        class : "kd-radio-holder"
      $radio = $ "<input/>"
        type  : "radio"
        name  : options.name
        value : radio.value
        class : "no-kdinput"
        id    : "#{@getId()}_radio_#{i}"
      $label = $ "<label/>"
        for   : "#{@getId()}_radio_#{i}"
        html  : radio.title
      $div.append $radio
      $div.append $label
      @domElement.append $div
    @domElement

  setDefaultValue:(value) ->
    @inputDefaultValue = value
    @setValue value

  getValue:()->
    @getDomElement().find("input:checked").val()

  setValue:(value)->
    @getDomElement().find("input[value='#{value}']").attr "checked","checked"