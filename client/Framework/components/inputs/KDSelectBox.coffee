class KDSelectBox extends KDInputView

  constructor:(options = {})->

    options.type = "select"


    super options

  setDomElement:(cssClass)->
    @inputName  = @getOption "name"
    name        = "name='#{@options.name}'"
    @domElement = $ """
        <div class='kdselectbox #{cssClass}'>
          <select #{name}></select>
          <span class='title'></span>
          <span class='arrows'></span>
        </div>"
      """
    @_$select = @$("select").eq(0)
    @_$title  = @$("span.title").eq(0)
    @domElement

  bindEvents:()->
    @_$select.bind "blur change focus",(event)=>
      # log "kdselectbox change" if event.type is "change"
      @getCallback()? @getValue() if event.type is "change"
      @emit event.type, event, @getValue()
      @handleEvent event
    super

  setDefaultValue:(value)->
    @getDomElement().val value if value isnt ""
    @_$select.val value
    @_$title.text @_$select.find("option[value=\"#{value}\"]").text()
    @inputDefaultValue = value
  getDefaultValue:()-> @inputDefaultValue

  getValue:()-> @_$select.val()
  setValue:(value)->
    @_$select.val value
    @change()

  makeDisabled:()->
    @setClass "disabled"
    @_$select.attr "disabled","disabled"

  makeEnabled:()->
    @unsetClass "disabled"
    @_$select.removeAttr "disabled"

  setSelectOptions:(options)->
    firstOption = null
    unless options.length
      for optGroup, subOptions of options
        $optGroup = $ "<optgroup label='#{optGroup}'/>"
        @_$select.append $optGroup
        for option in subOptions
          firstOption or= option
          $optGroup.append "<option value='#{option.value}'>#{option.title}</option>"
    else if options.length
      for option in options
        @_$select.append "<option value='#{option.value}'>#{option.title}</option>"
        firstOption or= option
    else
      warn "no valid options specified for the input:", @

    value = @getDefaultValue() or firstOption?.value or ""
    @_$select.val value + "" # casting to number in case, i don't remember why though. SY
    
    # escapedDefault = value.replace /\//g, '\\/'
    @_$title.text @_$select.find("option[value=\"#{value}\"]").text()

  removeSelectOptions:-> @_$select.find("option").remove()

  change:->
    @_$title.text @_$select.find("option[value=\"#{@getValue()}\"]").text()

  focus:-> @setClass 'focus'

  blur:-> @unsetClass 'focus'