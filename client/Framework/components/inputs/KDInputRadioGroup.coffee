#####
# Radio Group Class
#####

class KDInputRadioGroup extends KDInputView
  constructor:(options)->
    @inputSetType "radio"
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

  inputSetDefaultValue:(value) ->
    @inputDefaultValue = value
    @inputSetValue value

  inputGetValue:()->
    @getDomElement().find("input:checked").val()

  inputSetValue:(value)->
    @getDomElement().find("input[value='#{value}']").attr "checked","checked"