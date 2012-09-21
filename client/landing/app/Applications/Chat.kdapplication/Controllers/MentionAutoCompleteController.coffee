class MentionAutoCompleteController extends KDAutoCompleteController
  getLastInputWord: () ->
    inputValue = @getView().getValue()
    inputValue.split(/\s/).pop()

  keyUpOnInputView:(inputView, event)=>
    return if event.keyCode in [9,38,40] #tab
    #if event.shiftKey and event.which is 50 # Shift+2 = @

    lastWord = @getLastInputWord()
    if lastWord.length > 1 and lastWord[0] is '@'
      @updateDropdownContents()
    no

  fetch:(callback)->
    lastWord = @getLastInputWord()
    return if lastWord.length <= 1 or lastWord[0] isnt '@'
    @dropdownPrefix = lastWord.match(/^@(.*)/)[1]

    args = {}
    if @getOptions().fetchInputName
      args[@getOptions().fetchInputName] = @getView().getValue()
    else
      args = inputValue : @dropdownPrefix

    source = @getOptions().dataSource
    source args, callback

  # Overriden to prevent clearing the input.
  appendAutoCompletedItem: ->

  addItemToSubmitQueue:(item,data)->
    data or= item.getData()
    {itemDataPath, submitValuesAsText} = @getOptions()
    if data
      itemValue = if submitValuesAsText then JsPath.getAt data, itemDataPath else data
    else
      itemValue = item.getOptions().userInput
      data = JsPath itemDataPath, itemValue

    lastWord = @getLastInputWord()
    inputValue = @getView().getValue()

    if @isItemAlreadySelected data
      #inputValue = inputValue.replace lastWord, "@"
    else
      inputValue = inputValue.replace(new RegExp(lastWord+"$"), "@#{itemValue} ")
      @addSelectedItemData data
    
    @getView().setValue inputValue

    @dropdownPrefix = ""

  clearSelectedItemData: ->
    @getSelectedItemData().length = 0
