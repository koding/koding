#####
# KDSelectBox
#####

class KDSelectBox extends KDInputView
  constructor:(options)->
    options = $.extend
      type     : "select"       # mandatory
      cssClass : ""
    ,options  
    super options

  setDomElement:(cssClass)->
    @inputName = @options.name
    name = "name='#{@options.name}'"
    @domElement = $ """
        <div class='kdselectbox #{cssClass}'>
          <select #{name}></select>
          <span class='title'></span>
          <span class='arrows'></span>
        </div>"
      """
    @_$select = @$().find("select").eq(0)
    @_$title  = @$().find("span.title").eq(0)
    @domElement

  bindEvents:()->
    @_$select.bind "blur change focus",(event)=>
      # log "kdselectbox change" if event.type is "change"
      @inputGetCallback()? @inputGetValue()
      @emit event.type,event,@inputGetValue()
      @handleEvent event
    super

  inputSetDefaultValue:(value)-> 
    @getDomElement().val value if value isnt ""
    @_$select.val value
    @_$title.text @_$select.find("option[value=#{value}]").text()
    @inputDefaultValue = value
  inputGetDefaultValue:()-> @inputDefaultValue

  inputGetValue:()-> @_$select.val()
  inputSetValue:(value)-> 
    @_$select.val value
    @change()

  inputMakeDisabled:()->
    @setClass "disabled"
    @_$select.attr "disabled","disabled"

  inputMakeEnabled:()->
    @unsetClass "disabled"
    @_$select.removeAttr "disabled"

  inputSetSelectOptions:(options)->
    for option in options
      @_$select.append "<option value='#{option.value}'>#{option.title}</option>"
    @_$select.val @inputGetDefaultValue()
    value = @inputGetDefaultValue() + "" # casting number to string
    escapedDefault = value.replace /\//g, '\\/'
    @_$title.text @_$select.find("option[value=#{escapedDefault}]").text()

  change:->
    @_$title.text @_$select.find("option[value=#{@inputGetValue()}]").text()

  focus:->
    @setClass 'focus'

  blur:->
    @unsetClass 'focus'