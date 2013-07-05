class KDInputRadioGroup extends KDInputView
  constructor:(options)->

    options.type           or= 'radio'
    options.hideRadios      ?= no
    options.showIcons       ?= no
    options.cssClassPrefix or= ''

    super options

  setDomElement:->
    options = @getOptions()
    @domElement = $ "<fieldset class='#{@utils.curryCssClass 'radiogroup kdinput', options.cssClass}'></fieldset>"

    for radioOptions, i in options.radios
      radioOptions.visible   ?= yes
      radioOptions.callback or= ->

      disabledClass = if radioOptions.disabled then 'disabled ' else ''

      div      = $ "<div/>",
        class  : "kd-#{@getType()}-holder #{disabledClass}#{options.cssClassPrefix}#{@utils.slugify radioOptions.value}"

      radio    = $ "<input/>",
        type   : @getType()
        name   : options.name
        value  : radioOptions.value
        class  : "no-kdinput#{if options.hideRadios then ' hidden' else ''}"
        id     : "#{@getId()}_#{@getType()}_#{i}"
        change : radioOptions.callback

      if radioOptions.disabled
        radio[0].setAttribute 'disabled', 'disabled'

      label    = $ "<label/>",
        for    : "#{@getId()}_#{@getType()}_#{i}"
        html   : radioOptions.title
        class  : options.cssClassPrefix + @utils.slugify radioOptions.value

      div.append radio
      if options.showIcons
        div.append $ "<span/>", class  : "icon"
      div.append label
      @domElement.append div

      div.hide()  unless radioOptions.visible

    return @domElement

  click:(event)->
    input = $(event.target).closest(".kd-#{@getType()}-holder").find('input')
    return no if input[0].getAttribute('disabled') is 'disabled'
    @setValue input[0].getAttribute "value"

  setDefaultValue:(value) ->
    @inputDefaultValue = value
    @setValue value, yes

  getValue:-> @$('input[checked=checked]').val()

  setValue:(value, isDefault=no)->
    @$("input").attr "checked", no
    @$("input[value='#{value}']").attr "checked", "checked"
    @$("input[value='#{value}']").prop "checked", yes
    @$(".kd-radio-holder").removeClass 'active'
    @$(".kd-radio-holder.#{value}").addClass 'active'  if value? and value isnt ""

  getInputElements:->
    @getDomElement().find('input')

class KDRadioGroup extends KDInputRadioGroup

  constructor:(options={}, data)->

    options.hideRadios = yes
    options.showIcons  = yes

    super options, data

  setValue:(value, isDefault)->
    super
    @$().trigger "change" unless isDefault

