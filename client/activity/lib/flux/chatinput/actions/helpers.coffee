DropboxType       = require 'activity/flux/chatinput/dropboxtype'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'

module.exports = helpers =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    currentWord = helpers.getCurrentWord value, position

    checks = [
      { type : DropboxType.CHANNEL, text : currentWord, regexp : /^#(.*)/,            index : 1 }
      { type : DropboxType.EMOJI,   text : currentWord, regexp : /^\:(.+)/,           index : 1 }
      { type : DropboxType.MENTION, text : currentWord, regexp : /^@(.*)/,            index : 1 }
      { type : DropboxType.SEARCH,  text : value,       regexp : /^\/s(earch)? (.*)/, index : 2 }
      { type : DropboxType.COMMAND, text : value,       regexp : /^(\/[^\s]*)$/,      index : 1 }
    ]

    for check in checks
      { type, text, regexp, index } = check
      continue  unless text

      matchResult = text.match regexp
      return { type, query : matchResult[index] }  if matchResult


  getLastWord: (text) ->

    matchResult = text.match /([^\s]+)$/
    return matchResult?[1]


  getCurrentWord: (text, position) ->

    text     = text.substring 0, position
    lastWord = helpers.getLastWord text

    return lastWord

