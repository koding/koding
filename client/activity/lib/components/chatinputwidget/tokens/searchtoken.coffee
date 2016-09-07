isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
SearchDropbox     = require '../searchdropbox'
SearchActions     = require 'activity/flux/chatinput/actions/search'


module.exports = SearchToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    matchResult = value.match /^\/s(earch)? (.*)/
    return matchResult[2]  if matchResult


  getConfig: ->

    return {
      component            : SearchDropbox
      getters              :
        items              : 'dropboxSearchItems'
        selectedIndex      : 'searchSelectedIndex'
        selectedItem       : 'searchSelectedItem'
        flags              : 'searchFlags'
      horizontalNavigation : no
      submit               : ({ selectedItem, query, value, position }) ->
        return  unless selectedItem

        { initialChannelId, id } = selectedItem.get('message').toJS()
        command = {
          name   : '/search'
          params : { initialChannelId, messageId : id }
        }
        return { newValue : '', command }
    }


  triggerAction: (stateId, query) ->

    SearchActions.fetchData stateId, query
