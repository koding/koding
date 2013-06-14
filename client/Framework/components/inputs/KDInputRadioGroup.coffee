class KDInputRadioGroup extends KDInputView
  constructor:(options)->
    options.type           or= 'radio'
    options.cssClassPrefix or= ''

    super options

  setDomElement:->
    options = @getOptions()
    @domElement = $ "<fieldset class='#{@utils.curryCssClass 'radiogroup kdinput', options.cssClass}'></fieldset>"

    for radioOptions, i in options.radios
      radioOptions.visible   ?= yes
      radioOptions.callback or= ->

      div      = $ "<div/>",
        class  : "kd-#{@getType()}-holder #{options.cssClassPrefix}#{@utils.slugify radioOptions.value}"

      radio    = $ "<input/>",
        type   : @getType()
        name   : options.name
        value  : radioOptions.value
        class  : "no-kdinput"
        id     : "#{@getId()}_#{@getType()}_#{i}"
        change : radioOptions.callback

      label    = $ "<label/>",
        for    : "#{@getId()}_#{@getType()}_#{i}"
        html   : radioOptions.title
        class  : options.cssClassPrefix + @utils.slugify radioOptions.value

      div.append radio
      div.append label
      @domElement.append div

      div.hide()  unless radioOptions.visible

    return @domElement

  click:(event)->
    input = $(event.target).closest(".kd-#{@getType()}-holder").find('input')
    @setValue input[0].getAttribute "value"

  setDefaultValue:(value) ->
    @inputDefaultValue = value
    @setValue value

  getValue:-> @$('input[checked=checked]').val()

  setValue:(value)->
    @$("input").attr "checked", no
    @$("input[value='#{value}']").attr "checked", "checked"
    @$("input[value='#{value}']").prop "checked", yes
    @$(".kd-radio-holder").removeClass 'active'
    @$(".kd-radio-holder.#{value}").addClass 'active'  if value?

  getInputElements:->
    @getDomElement().find('input')
