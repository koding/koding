textHelpers = require 'activity/util/textHelpers'

module.exports = helpers =

  getCursorPosition: (textInput) -> textInput.selectionStart


  setCursorPosition: (textInput, position) ->

    textInput.focus()
    textInput.setSelectionRange position, position


  replaceWordAtPosition: (value, position, word) ->

    textBeforePosition = value.substring 0, position
    textToReplace      = textHelpers.getLastWord textBeforePosition
    startReplaceIndex  = textBeforePosition.lastIndexOf textToReplace
    endReplaceIndex    = position

    newValue    = value.substring 0, startReplaceIndex
    newValue   += word
    newPosition = newValue.length
    newValue   += value.substring endReplaceIndex

    return { newValue, newPosition }


  parseCommand: (value) ->

    matchResult = value.match /^(\/[^\s]+)(\s.*)?/
    return  unless matchResult

    name     = matchResult[1]
    paramStr = matchResult[2]
    if paramStr
      params = paramStr.trim().split ' '
      params = (param for param in params when param isnt '')

    return { name, params }
