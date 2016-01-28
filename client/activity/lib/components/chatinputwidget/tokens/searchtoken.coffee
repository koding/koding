kd                = require 'kd'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
SearchDropbox     = require '../searchdropbox'
SearchActions     = require 'activity/flux/chatinput/actions/search'
ChannelActions    = require 'activity/flux/actions/channel'

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
      processConfirmedItem : (item, query) ->
        { initialChannelId, id } = item.get('message').toJS()
        return {
          type     : 'command'
          value    :
            name   : '/search'
            params : { initialChannelId, messageId : id }
        }
    }


  triggerAction: (stateId, query) ->

    SearchActions.fetchData stateId, query
