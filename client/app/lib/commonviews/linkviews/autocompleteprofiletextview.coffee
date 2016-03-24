ProfileTextView = require './profiletextview'
getFullnameFromAccount = require '../../util/getFullnameFromAccount'


module.exports = class AutoCompleteProfileTextView extends ProfileTextView

  highlightMatch: (str, isNick = no) ->

    { userInput } = @getOptions()
    unless userInput
      str
    else if str
      str = str.replace RegExp(userInput, 'gi'), (match) =>
        if isNick then @setClass 'nick-matches'
        return "<b>#{match}</b>"

  pistachio: ->

    name = getFullnameFromAccount @getData()
    "#{@highlightMatch name}" +
      if @getOptions().shouldShowNick then """
        <span class='nick'>
          (@{{@highlightMatch #(profile.nickname), yes}})
        </span>
        """
      else ''
