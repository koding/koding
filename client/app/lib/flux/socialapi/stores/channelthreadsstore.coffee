Nuclear              = require 'nuclear-js'
toImmutable          = require 'app/util/toImmutable'
actions              = require '../actions/actiontypes'

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
 * @typedef {Immutable.Map} IMThread
 * @property {string} channelId
 * @property {Immutable.Map<string, string>} messages
###

###*
 * @typedef {Immutable.Map<string, IMThread>} IMThreadCollection
###

module.exports = class ChannelThreadsStore extends Nuclear.Store

  @getterPath = 'ChannelThreadsStore'

  getInitialState: -> toImmutable {}


  initialize: ->

    @on actions.LOAD_MESSAGE_SUCCESS, @handleLoadMessageSuccess

    @on actions.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_MESSAGE_SUCCESS, @handleCreateMessageSuccess
    @on actions.CREATE_MESSAGE_FAIL, @handleCreateMessageFail

    @on actions.REMOVE_MESSAGE_SUCCESS, @handleRemoveMessageSuccess

    @on actions.LOAD_CHANNEL_SUCCESS, @addNewThread
    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @addNewThread
    @on actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, @addNewThread


  ###*
   * General handler for message load actions.
   *
   * @param {IMThreadCollection} threads
   * @param {object} payload
   * @param {string} payload.channelId
   * @param {SocialMessage} payload.message
   * @return {IMThreadCollection} nextState
  ###
  handleLoadMessageSuccess: (threads, { channelId, message }) ->

    return threads  if message.typeConstant is 'reply'

    return addMessage threads, channelId, message.id


  ###*
   * Generic handler for initiating a thread with given channel.
   *
   * @param {IMThreadCollection} threads
   * @param {object} payload
   * @param {SocialChannel} channel
   * @return {IMThreadCollection} nextState
  ###
  addNewThread: (threads, { channel }) ->

    unless threads.has channel.id
      return initThread threads, channel.id

    return threads


  ###*
   * Handler for `CREATE_MESSAGE_BEGIN` action.
   * It adds given clientRequestId to messages map.
   *
   * @param {IMThreadCollection} threads
   * @param {object} payload
   * @param {string} channelId
   * @param {string} clientRequestId
   * @return {IMThreadCollection} nextState
  ###
  handleCreateMessageBegin: (threads, { channelId, clientRequestId }) ->

    return addMessage threads, channelId, clientRequestId


  ###*
   * Handler for `CREATE_MESSAGE_SUCCESS` action.
   * It first removes fake message id if it exists, then adds message's id to
   * thread.
   *
   * @param {IMThreadCollection} threads
   * @param {object} payload
   * @param {string} channelId
   * @param {string} clientRequestId
   * @param {SocialMessage} message
   * @return {IMThreadCollection} nextState
  ###
  handleCreateMessageSuccess: (threads, { channelId, clientRequestId, message }) ->

    if clientRequestId
      threads = removeMessage threads, clientRequestId

    return addMessage threads, channelId, message.id


  ###*
   * Handler for `CREATE_MESSAGE_FAIL` action.
   * It removes fake message id with from thread.
   *
   * @param {IMThreadCollection} threads
   * @param {object} payload
   * @param {string} channelId
   * @param {string} clientRequestId
   * @return {IMThreadCollection} nextState
  ###
  handleCreateMessageFail: (threads, { channelId, clientRequestId }) ->

    return removeMessage threads, clientRequestId


  ###*
   * Handler for `REMOVE_MESSAGE_SUCCESS` action.
   * It removes given messageId from thread's message list.
   *
   * @param {IMThreadCollection} threads
   * @param {object} payload
   * @param {string} channelId
   * @param {string} messageId
   * @param {IMTreadCollection} nextState
  ###
  handleRemoveMessageSuccess: (threads, { messageId }) ->
    return removeMessage threads, messageId


###*
 * Adds given messageId to thread with given channelId.
 *
 * @param {IMThreadCollection} threads
 * @param {string} channelId
 * @param {string} messageId
 * @return {IMThreadCollection} _threads
###
addMessage = (threads, channelId, messageId) ->

  unless threads.has channelId
    threads = initThread threads, channelId

  return threads.setIn [channelId, 'messages', messageId], messageId



###*
 * Since a message may belong to many threads, it removes given messageId from
 * each thread.
 *
 * @param {IMThreadCollection} threads
 * @param {string} messageId
 * @return {IMThreadCollection} _threads
###
removeMessage = (threads, messageId) ->

  # for each thread
  return threads.map (thread) ->
    # update messages list with filtering out given messageId.
    thread.update 'messages', (messages) -> messages.remove messageId


###*
 * Initialize a channel record in channels collection.
 *
 * @param {IMThreadCollection} threads
 * @param {string} channelId
 * @return {IMThreadCollection} _threads
###
initThread = (threads, channelId) ->

  return threads.set channelId, createThread channelId


###*
 * Returns an empty thread.
 *
 * @param {string} channelId
 * @return {IMThread} thread
###
createThread = (channelId) ->

  return toImmutable { channelId, messages: toImmutable({}) }
