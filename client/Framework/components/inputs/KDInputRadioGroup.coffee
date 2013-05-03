class KDInputRadioGroup extends KDInputView
  constructor:(options)->
    options.type           or= 'radio'
    options.cssClassPrefix or= ''

    super options

  setDomElement:()->
    options = @getOptions()
    @domElement = $ "<fieldset class='#{@utils.curryCssClass 'radiogroup kdinput', options.cssClass}'></fieldset>"

    for radioOptions, i in options.radios
      radioOptions.visible   ?= yes
      radioOptions.callback or= ->

      div     = $ "<div/>",
        class : "kd-#{@getType()}-holder #{options.cssClassPrefix}#{@utils.slugify radioOptions.value}"

      radio   = $ "<input/>",
        type   : @getType()
        name   : options.name
        value  : radioOptions.value
        class  : "no-kdinput"
        id     : "#{@getId()}_#{@getType()}_#{i}"
        change : radioOptions.callback

      label   = $ "<label/>",
        for   : "#{@getId()}_#{@getType()}_#{i}"
        html  : radioOptions.title
        class : options.cssClassPrefix + @utils.slugify radioOptions.value

      div.append radio
      div.append label
      @domElement.append div

      if not radioOptions.visible
        div.hide()
    @domElement

  click:-> @setValue @getValue()

  setDefaultValue:(value) ->
    @inputDefaultValue = value
    @setValue value

  getValue:()->
    @getDomElement().find("input:checked").val()

  setValue:(value)->
    # @getDomElement().find("input[value='#{value}']").parent().siblings().removeClass('checked')
    # @getDomElement().find("input[value='#{value}']").parent().addClass('checked')
    @getDomElement().find("input[value='#{value}']").attr "checked","checked"
    @getDomElement().find(".kd-radio-holder").removeClass 'active'
    @getDomElement().find(".kd-radio-holder.#{value}").addClass 'active'

  getInputElements:->
    @getDomElement().find('input')