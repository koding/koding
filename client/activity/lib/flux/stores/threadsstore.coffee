Nuclear              = require 'nuclear-js'
whoami               = require 'app/util/whoami'
toImmutable          = require 'app/util/toImmutable'
actionTypes          = require '../actions/actiontypes'
generateDummyMessage = require 'app/util/generateDummyMessage'

###*
 * A thin data structure to hold message list associated with given channelId.
 *
 * Messages collection is a map instead of a list, to be able to add/remove
 * things with messageId.
 *
 *     # remove message id from list:
 *     # imagine a list: Immutable.List([messageId, messageId2])
 *     list = list.remove(list.indexOf messageId)
 *     # with maps you can:
 *     # imagine a map: Immutable.Map({messageId, messageId2, messageId3})
 *     map = map.remove messageId
 *
 * @typedef {Immutable.Map} Thread
 * @property {string} channelId
 * @property {Immutable.Map<string, string>} messages
###

###*
 * @typedef {Immutable.Map<string, Thread>} ThreadCollection
###

module.exports = class ThreadsStore extends Nuclear.Store

  getInitialState: -> toImmutable {}


  initialize: ->

    @on actionTypes.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actionTypes.CREATE_MESSAGE_SUCCESS, @handleCreateMessageSuccess
    @on actionTypes.CREATE_MESSAGE_FAIL, @handleCreateMessageFail

    @on actionTypes.REMOVE_MESSAGE_SUCCESS, @handleRemoveMessageSuccess


  ###*
   * Handler for `CREATE_MESSAGE_BEGIN` action.
   * It adds given clientRequestId to messages map.
   *
   * @param {ThreadCollection} currentState
   * @param {object} payload
   * @param {string} channelId
   * @param {string} clientRequestId
   * @return {ThreadCollection} nextState
  ###
  handleCreateMessageBegin: (currentState, { channelId, clientRequestId }) ->

    return addMessage currentState, channelId, clientRequestId


  ###*
   * Handler for `CREATE_MESSAGE_SUCCESS` action.
   * It first removes fake message id if it exists, then adds message's id to
   * thread.
   *
   * @param {ThreadCollection} currentState
   * @param {object} payload
   * @param {string} channelId
   * @param {string} clientRequestId
   * @param {SocialMessage} message
   * @return {ThreadCollection} nextState
  ###
  handleCreateMessageSuccess: (currentState, { channelId, clientRequestId, message }) ->

    if clientRequestId
      currentState = removeMessage currentState, channelId, clientRequestId

    return addMessage currentState, channelId, message.id


  ###*
   * Handler for `CREATE_MESSAGE_FAIL` action.
   * It removes fake message id with from thread.
   *
   * @param {ThreadCollection} currentState
   * @param {object} payload
   * @param {string} channelId
   * @param {string} clientRequestId
   * @return {ThreadCollection} nextState
  ###
  handleCreateMessageFail: (currentState, { channelId, clientRequestId }) ->

    return removeMessage currentState, channelId, clientRequestId


  ###*
   * Handler for `REMOVE_MESSAGE_SUCCESS` action.
   * It removes given messageId from thread's message list.
   *
   * @param {ThreadCollection} currentState
   * @param {object} payload
   * @param {string} channelId
   * @param {string} messageId
   * @param {TreadCollection} nextState
  ###
  handleRemoveMessageSuccess: (currentState, { channelId, messageId }) ->

    return removeMessage currentState, messageId


###*
 * Adds given messageId to thread with given channelId.
 *
 * @param {ThreadCollection} threads
 * @param {string} channelId
 * @param {string} messageId
 * @return {ThreadCollection} _threads
###
addMessage = (threads, channelId, messageId) ->

  unless threads.has channelId
    threads = initThread threads, channelId

  threads = threads.update channelId, (thread) ->
    thread.setIn ['messages', messageId], messageId

  return threads


###*
 * Since a message may belong to many threads, it removes given messageId from
 * each thread.
 *
 * @param {ThreadCollection} threads
 * @param {string} messageId
 * @return {ThreadCollection} _threads
###
removeMessage = (threads, messageId) ->

  # for each thread
  return threads.map (thread) ->
    # update messages list with filtering out given messageId.
    thread.update 'messages', (messages) -> messages.filter (id) -> id isnt messageId


###*
 * Initialize a channel record in channels collection.
 *
 * @param {ThreadCollection} threads
 * @param {string} channelId
 * @return {ThreadCollection} _threads
###
initThread = (threads, channelId) ->

  return threads.set channelId, createThread channelId


###*
 * Returns an empty thread.
 *
 * @param {string} channelId
 * @return {Thread} thread
###
createThread = (channelId) ->

  return toImmutable { channelId, messages: toImmutable({}) }


