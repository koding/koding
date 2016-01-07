kd                = require 'kd'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
SearchDropbox     = require 'activity/components/searchdropbox'
SearchActions     = require 'activity/flux/chatinput/actions/search'
ChannelActions    = require 'activity/flux/actions/channel'

module.exports = SearchToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    matchResult = value.match /^\/s(earch)? (.*)/
    return matchResult[2]  if matchResult


  getConfig: ->

    return {
      component              : SearchDropbox
      getters                :
        items                : 'dropboxSearchItems'
        selectedIndex        : 'searchSelectedIndex'
        selectedItem         : 'searchSelectedItem'
        flags                : 'searchFlags'
      horizontalNavigation   : no
      handleItemConfirmation : (item, query) ->
        { initialChannelId, id } = item.get('message').toJS()
        ChannelActions.loadChannel(initialChannelId).then ({ channel }) ->
          kd.singletons.router.handleRoute "/Channels/#{channel.name}/#{id}"
    }


  triggerAction: (stateId, query) ->

    SearchActions.fetchData stateId, query
