actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/base/store'


module.exports = class MessageLikersStore extends KodingFluxStore

  @getterPath = 'MessageLikersStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_POPULAR_MESSAGE_SUCCESS, @handleMessageLoad
    @on actions.LOAD_MESSAGE_SUCCESS, @handleMessageLoad
    @on actions.LOAD_COMMENT_SUCCESS, @handleMessageLoad
    @on actions.CREATE_MESSAGE_SUCCESS, @handleMessageLoad
    @on actions.CREATE_COMMENT_SUCCESS, @handleMessageLoad

    @on actions.LIKE_MESSAGE_BEGIN, @setLiker
    @on actions.LIKE_MESSAGE_SUCCESS, @setLiker
    @on actions.LIKE_MESSAGE_FAIL, @removeLiker

    @on actions.UNLIKE_MESSAGE_BEGIN, @removeLiker
    @on actions.UNLIKE_MESSAGE_SUCCESS, @removeLiker
    @on actions.UNLIKE_MESSAGE_FAIL, @setLiker


  ###*
   * Loads given message or comment's actors preview into message liker
   * container.
   *
   * @param {Immutable.Map} likers
   * @param {object} payload
   * @param {SocialMessage=} message
   * @param {SocialMessage=} comment
   * @param {Immutable.Map} nextState
  ###
  handleMessageLoad: (likers, { message, comment }) ->

    # to make this method idempotent
    message or= comment

    { actorsPreview } = message.interactions.like

    likers = ensureContainer likers, message.id

    return likers.withMutations (likers) ->
      actorsPreview.forEach (userId) ->
        likers = likers.setIn [message.id, userId], userId


  ###*
   * Adds given userId to message liker container.
   *
   * @param {Immutable.Map} likers
   * @param {object} payload
   * @param {string} messageId
   * @param {string} userId
   * @param {Immutable.Map} nextState
  ###
  setLiker: (likers, { messageId, userId }) ->

    likers = ensureContainer likers, messageId

    return likers.setIn [messageId, userId], userId


  ###*
   * Removes given userId from message liker container.
   *
   * @param {Immutable.Map} likers
   * @param {object} payload
   * @param {string} messageId
   * @param {string} userId
   * @param {Immutable.Map} nextState
  ###
  removeLiker: (likers, { messageId, userId }) ->

    likers = ensureContainer likers, messageId

    return likers.removeIn [messageId, userId]


###*
 * Ensures that given likers map has a container for given messageId.
 *
 * @param {Immutable.Map} likers
 * @param {string} messageId
 * @param {Immutable.Map} _likers
###
ensureContainer = (likers, messageId) ->

  unless likers.has messageId
    likers = likers.set messageId, immutable.Map()

  return likers
