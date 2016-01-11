module.exports = textHelpers =

  getLastWord: (text) ->

    matchResult = text.match /([^\s]+)$/
    return matchResult?[1]


  getWordByPosition: (text, position) ->

    text     = text.substring 0, position
    lastWord = textHelpers.getLastWord text

    return lastWord
