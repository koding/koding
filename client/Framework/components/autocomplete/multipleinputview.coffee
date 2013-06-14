# SIMPLE AUTOCOMPLETE VIEW
class KDSimpleAutocomplete extends KDAutoComplete
  addItemToSubmitQueue: (item) ->
    itemValue = JsPath.getAt item.getData(), @getOptions().itemDataPath
    @setValue itemValue

  keyUp: (event) ->
    return if event.keyCode is 13
    super

  showNoDataFound: ->
    @dropdown.removeAllItems()
    @hideDropdown()

class KDMultipleInputView extends KDSimpleAutocomplete
  constructor: (options) ->
    @_values = []
    options = $.extend {
      icon: 'noicon'
      title: ''
    }, options
    super options

  focus:(pubInst,event)->
    (KD.getSingleton "windowController").setKeyView @

  viewAppended: ->
    # log 'view appended'
    @list = new MultipleInputListView delegate: @
    @addSubView @list

  $input:-> @$().find("input.main").eq(0)

  getValues: ->
    @_values

  rearrangeInputWidth: ->
    no

  addItemToSubmitQueue: ->
    super
    @inputAddCurrentValue()

  keyUp: (event) ->
    if event.keyCode is 13
      @inputAddCurrentValue()

    super

  inputRemoveValue: (value) ->
    index = @_values.indexOf value
    if index > -1
      @_values.splice index, 1

    @_inputChanged()

  clear: ->
    @_values = []
    @removeAllItems()
    @_inputChanged()

  inputAddCurrentValue: ->
    value = @$input().val()
    value = $.trim value

    return if value in @_values or value is ''

    @_values.push value
    @$input().val ''
    @list.addItems [value]

    @_inputChanged()

  _inputChanged: ->
    if not @_hiddenInputs
      @_hiddenInputs = []

    #remove old inputs
    for input in @_hiddenInputs
      input.destroy()

    inputName = @getOptions().name
    for value, index in @_values
      newInput = new KDInputView type: 'hidden', name: inputName + "[#{index}]", defaultValue: value
      @_hiddenInputs.push newInput
      @addSubView newInput

    @emit 'MultipleInputChanged', values: @getValue()

  click: (event) ->
    if $(event.target).hasClass 'addNewItem'
      @inputAddCurrentValue()

  setDomId:->
    @$input().attr "id", @getDomId()
    @$input().data "data-id", @getId()
    # @$input().attr "name", @getName()

  setDomElement: ->
    # <p class='search-tags clearfix'><span>Ryan <cite>x</cite></span></p>
    @domElement = $ "<div class='filter kdview'>
      <h2>#{@getOptions().title}</h2>
      <div class='clearfix'>
        <span class='#{@getOptions().icon}'></span>
        <input type='text' class='main'>
        <a href='#' class='addNewItem'>+</a>
      </div>
    </div>"
