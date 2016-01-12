actions              = require '../actions/actiontypes'
immutable            = require 'immutable'
KodingFluxStore      = require 'app/flux/base/store'

module.exports = class FilteredChannelMessagesIdsStore extends KodingFluxStore

  @getterPath = 'FilteredChannelMessagesIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.CHANNEL_MESSAGES_SEARCH_SUCCESS, @handleSearchSuccess


  ###*
   * Adds given channel to privateMessageIds container.
   *
   * @param {Immutable.Map} privateMessageIds
   * @param {object} payload
   * @param {object} payload.channel
   * @return {Immutable.Map} nextState
  ###
  handleSearchSuccess: (filteredIds, { channelId, messages }) ->

    filteredIds = immutable.Map()

    return filteredIds.withMutations (map) ->
      map.set message.id, message.id for message in messages
      return map

