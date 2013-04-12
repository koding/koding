class KDInputRadioGroup extends KDInputView
  constructor:(options)->
    @setType "radio"
    super options

  setDomElement:()->
    options = @getOptions()
    @domElement = $ "<fieldset class='#{@utils.curryCssClass 'radiogroup kdinput', options.cssClass}'></fieldset>"

    for radioOptions, i in options.radios
      div     = $ "<div/>",
        class : "kd-radio-holder #{@utils.slugify radioOptions.value}"

      radio   = $ "<input/>",
        type  : "radio"
        name  : options.name
        value : radioOptions.value
        class : "no-kdinput"
        id    : "#{@getId()}_radio_#{i}"

      label   = $ "<label/>",
        for   : "#{@getId()}_radio_#{i}"
        html  : radioOptions.title
        class : @utils.slugify radioOptions.value

      div.append radio
      div.append label
      @domElement.append div
    @domElement

  setDefaultValue:(value) ->
    @inputDefaultValue = value
    @setValue value

  getValue:()->
    @getDomElement().find("input:checked").val()

  setValue:(value)->
    # @getDomElement().find("input[value='#{value}']").parent().siblings().removeClass('checked')
    # @getDomElement().find("input[value='#{value}']").parent().addClass('checked')
    @getDomElement().find("input[value='#{value}']").attr "checked","checked"