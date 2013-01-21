class NoAutocompleteMultipleListView extends KDView
  constructor: (options, data) ->
    options ?= {}
    defaults =
      cssClass: 'common-view input-with-extras'
    options = $.extend defaults, options
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
      @addSubView @input  = new NoAutocompleteInputView input

    if button
      defaults =
        callback:(event)=>
          event.preventDefault()
          event.stopPropagation()
          @input.inputAddCurrentValue()

      button = $.extend defaults, button
      @addSubView @button = new KDButtonView button

class MultipleInputListView extends KDListView
  setDomElement: ->
    # <span>Ryan <cite>x</cite></span>
    @domElement = $ "<p class='search-tags clearfix'></p>"

  addItems: (items) ->
    for item in items
      newItem = new MultipleListItemView {delegate: @}, item
      @addItemView newItem

  removeListItem: (instance) ->
    super instance
    @getDelegate().inputRemoveValue instance.getData()

class MultipleListItemView extends KDListItemView
  click: (event) ->
    if $(event.target).hasClass 'removeIcon'
      @getDelegate().removeListItem @

  setDomElement: ->
    @domElement = $ '<span />'
  partial: ->
    "#{@getData()} <cite class='removeIcon'>x</cite>"
