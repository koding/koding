class CommonView_InputWithButton extends KDFormView

  constructor:(options = {},data)->

    options = $.extend
      button    : null          # a KDButtonView instance
      input     : null          # a KDInputView instance -type text, password or textarea
      icon      : null          # a String of cssClass of icon in a span
      cssClass  : ""
    ,options
    options.cssClass = "common-view input-with-extras #{options.cssClass}"
    super options,data

  viewAppended:()->

    {icon,input,button} = @getOptions()

    if icon
      @setClass "with-icon"
      options =
        tagName  : "span"
        cssClass : "icon #{icon}"
      @addSubView @icon   = new KDCustomHTMLView options

    if input
      @addSubView @input  = new KDInputView input

    if button
      button.callback ?= noop
      button.type     or= "submit"
      @addSubView @button = new KDButtonView button

    @input.on "focus", => @setClass "focus"
    @input.on "blur", => @unsetClass "focus validation-error"
    @input.on "ValidationError", => @setClass "validation-error"
    @input.on "ValidationPassed", => @unsetClass "validation-error"

  getValue:()->

    @input.getValue()

  setValue:(value)->

    @input.setValue value


class CommonView_AddTagView extends NoAutocompleteMultipleListView
  constructor: (options = {}, data) ->
    options = $.extend
      cssClass: 'add-tag-view'
    ,options
    super options, data

  viewAppended: ->
    {icon,input,button} = @options

    if icon
      @setClass "with-icon"
      options =
        tagName  : "span"
        cssClass : "icon #{icon}"
      @addSubView @icon   = new KDCustomHTMLView options

    if input
      @addSubView @input  = new NoAutocompleteInputViewForTags input

    if button and input
      defaults =
        callback:(event)=>
          event.preventDefault()
          event.stopPropagation()
          @input.inputAddCurrentValue()

      button = $.extend defaults, button
      @input.addSubView @button = new KDButtonView button

class NoAutocompleteInputViewForTags extends NoAutocompleteInputView
  constructor: (options = {}, data) ->
    options = $.extend
      cssClass: 'common-view input-with-extras'
    ,options
    super options, data

  viewAppended: ->
    @list = new MultipleInputListView delegate: @
    @parent.addSubView @list

