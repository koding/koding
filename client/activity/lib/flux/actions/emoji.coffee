kd             = require 'kd'
actionTypes    = require '../actions/actiontypes'
EmojiConstants = require 'activity/flux/emojiconstants'

setEmojiQuery = (query) ->

  { SET_EMOJI_QUERY } = actionTypes

  query ?= ''
  dispatch SET_EMOJI_QUERY, { query }
  selectEmoji EmojiConstants.UNSELECTED_EMOJI_INDEX


clearEmojiQuery = -> setEmojiQuery ''


selectEmoji = (index) ->

  { SET_SELECTED_EMOJI_INDEX } = actionTypes

  dispatch SET_SELECTED_EMOJI_INDEX, { index }


moveToNextEmoji = ->

  { MOVE_TO_NEXT_EMOJI_INDEX } = actionTypes

  dispatch MOVE_TO_NEXT_EMOJI_INDEX


moveToPrevEmoji = ->

  { MOVE_TO_PREV_EMOJI_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_EMOJI_INDEX


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setEmojiQuery
  clearEmojiQuery
  selectEmoji
  moveToNextEmoji
  moveToPrevEmoji
}
