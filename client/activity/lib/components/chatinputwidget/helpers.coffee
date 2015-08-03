formatEmojiName = require 'activity/util/formatEmojiName'

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


  getEmojiQuery: (textInput) ->

    textBeforeCursor = helpers.getTextBeforeCursor textInput
    lastWord         = helpers.getLastWord textBeforeCursor

    matchResult = lastWord?.match /^\:(.+)/
    return matchResult?[1]


  insertEmoji: (textInput, emoji) ->

    textBeforeCursor  = helpers.getTextBeforeCursor textInput
    textToReplace     = helpers.getLastWord textBeforeCursor
    startReplaceIndex = textBeforeCursor.lastIndexOf textToReplace
    endReplaceIndex   = helpers.getCursorPosition textInput

    value             = textInput.value
    textBeforeCursor  = value.substring(0, startReplaceIndex)
    textBeforeCursor += formatEmojiName(emoji) + " "
    cursorPosition    = textBeforeCursor.length
    newValue          = textBeforeCursor + value.substring endReplaceIndex

    return { value : newValue, cursorPosition }