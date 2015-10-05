_                     = require 'lodash'
kd                    = require 'kd'
actionTypes           = require './actiontypes'
showErrorNotification = require 'app/util/showErrorNotification'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to add participant to new channel by given accountId
 *
 * @param {string} accountId
###
addParticipant = (accountId) ->

  { ADD_PARTICIPANT_TO_NEW_CHANNEL } = actionTypes
  dispatch ADD_PARTICIPANT_TO_NEW_CHANNEL, { accountId }


###*
 * Action to remove participant from new channel by given accountId
 *
 * @param {string} accountId
###
removeParticipant = (accountId) ->

  { REMOVE_PARTICIPANT_FROM_NEW_CHANNEL } = actionTypes
  dispatch REMOVE_PARTICIPANT_FROM_NEW_CHANNEL, { accountId }

###*
 * Action to remove all participants from new channel
 *
 * @param {string} accountId
###
removeAllParticipants = ->

  { REMOVE_ALL_PARTICIPANTS_FROM_NEW_CHANNEL } = actionTypes
  dispatch REMOVE_ALL_PARTICIPANTS_FROM_NEW_CHANNEL


###*
 * It creates a public channel by given options
 *
 * @param {object} options
 * @param {string} payload.body
 * @param {string} payload.name
 * @param {string} payload.purpose
 * @param {array} payload.recipients
###
createPublicChannel = (options = {}) ->

  { CREATE_PUBLIC_CHANNEL
    CREATE_PUBLIC_CHANNEL_FAIL
    CREATE_PUBLIC_CHANNEL_SUCCESS } = actionTypes

  dispatch CREATE_PUBLIC_CHANNEL, options

  kd.singletons.socialapi.channel.createChannelWithParticipants options, (err, channels) ->
    if err
      dispatch CREATE_PUBLIC_CHANNEL_FAIL, { err }
      showErrorNotification err, userMessage: err.message
      return

    [channel] = channels
    dispatch CREATE_PUBLIC_CHANNEL_SUCCESS, { channel }


###*
 * It creates a private channel by given options
 *
 * @param {object} options
 * @param {string} payload.body
 * @param {string} payload.name
 * @param {string} payload.purpose
 * @param {array}  payload.recipients
###
createPrivateChannel = (options = {}) ->

  { CREATE_PRIVATE_CHANNEL
    CREATE_PRIVATE_CHANNEL_FAIL
    CREATE_PRIVATE_CHANNEL_SUCCESS } = actionTypes

  dispatch CREATE_PRIVATE_CHANNEL, options

  _options = _mapPrivateChannelOptions options

  kd.singletons.socialapi.channel.createChannelWithParticipants _options, (err, channels) ->
    if err
      dispatch CREATE_PRIVATE_CHANNEL_FAIL, { err }
      showErrorNotification err, userMessage: err.message
      return

    [channel] = channels
    dispatch CREATE_PRIVATE_CHANNEL_SUCCESS, { channel }


_mapPrivateChannelOptions = (options) ->

  # don't modify arg
  _options = _.assign {}, options

  _options['payload'] or= {}
  _options['payload']['description'] = options.purpose or ''
  _options['purpose'] = options.name or ''
  _options['name'] = ''

  return _options


module.exports = {
  addParticipant
  removeParticipant
  createPublicChannel
  createPrivateChannel
  removeAllParticipants
}

