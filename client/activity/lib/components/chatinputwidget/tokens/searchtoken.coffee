isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
SearchDropbox     = require 'activity/components/searchdropbox'
SearchActions     = require 'activity/flux/chatinput/actions/search'

module.exports = SearchToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    matchResult = value.match /^\/s(earch)? (.*)/
    return matchResult[2]  if matchResult


  getConfig: ->

    return {
      component       : SearchDropbox
      getters         :
        items         : 'dropboxSearchItems'
        selectedIndex : 'searchSelectedIndex'
        selectedItem  : 'searchSelectedItem'
        flags         : 'searchFlags'
    }


  triggerAction: (stateId, query) ->

    SearchActions.fetchData stateId, query

