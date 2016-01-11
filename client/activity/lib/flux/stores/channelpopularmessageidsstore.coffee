actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'

###*
 * @typedef {Immutable.Map<channelId, Immutable.List<messageId, messageId>>} IMPopularIdsCollection
###

module.exports = class ChannelPopularMessageIdsStore extends KodingFluxStore

  @getterPath = 'ChannelPopularMessageIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_POPULAR_MESSAGE_SUCCESS, @handleLoadSuccess


  ###*
   * Adds given message's id to message list of given channelId.
   *
   * @param {IMPopularIdsCollection} popularMessageIds
   * @param {object} payload
   * @param {string} payload.channelId
   * @param {SocialMessage} payload.message
   * @return {IMPopularIdsCollection} nextState
  ###
  handleLoadSuccess: (popularMessageIds, { channelId, message }) ->

    unless popularMessageIds.has channelId
      popularMessageIds.set channelId, immutable.Map()

    return popularMessageIds.setIn [channelId, message.id], message.id
