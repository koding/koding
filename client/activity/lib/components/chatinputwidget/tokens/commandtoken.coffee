isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
helpers           = require '../helpers'
CommandDropbox    = require '../commanddropbox'

module.exports = CommandToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    matchResult = value.match /^(\/[^\s]*)$/
    return matchResult[1]  if matchResult


  getConfig: ->

    return {
      component            : CommandDropbox
      getters              :
        items              : 'dropboxCommands'
        selectedIndex      : 'commandsSelectedIndex'
        selectedItem       : 'commandsSelectedItem'
      horizontalNavigation : no
      submit               : ({ selectedItem, query, value, position }) ->
        return  unless selectedItem

        newWord = "#{selectedItem.get 'name'} #{selectedItem.get 'paramPrefix', ''}"
        return helpers.replaceWordAtPosition value, position, newWord
    }
