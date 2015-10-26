module.exports = helpers =

  getCursorPosition: (textInput) -> textInput.selectionStart


  setCursorPosition: (textInput, position) ->

    textInput.focus()
    textInput.setSelectionRange position, position


  getTextBeforeCursor: (textInput) ->

    position = helpers.getCursorPosition textInput
    value    = textInput.value

    return value.substring 0, position


  getLastWord: (str) ->

    matchResult = str.match /([^\s]+)$/
    return matchResult?[1]


  getCurrentWord: (textInput) ->

    textBeforeCursor = helpers.getTextBeforeCursor textInput
    lastWord         = helpers.getLastWord textBeforeCursor

    return lastWord


  insertDropboxItem: (textInput, item) ->

    textBeforeCursor  = helpers.getTextBeforeCursor textInput
    textToReplace     = helpers.getLastWord textBeforeCursor
    startReplaceIndex = textBeforeCursor.lastIndexOf textToReplace
    endReplaceIndex   = helpers.getCursorPosition textInput

    value             = textInput.value
    textBeforeCursor  = value.substring(0, startReplaceIndex)
    textBeforeCursor += item
    cursorPosition    = textBeforeCursor.length
    newValue          = textBeforeCursor + value.substring endReplaceIndex

    return { value : newValue, cursorPosition }


  parseCommand: (value) ->

    matchResult = value.match /^(\/[^\s]+)(\s.*)?/
    return  unless matchResult

    name     = matchResult[1]
    paramStr = matchResult[2]
    if paramStr
      params = paramStr.trim().split ' '
      params = (param for param in params when param isnt '')

    return { name, params }

