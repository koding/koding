kd             = require 'kd'
actionTypes    = require '../actions/actiontypes'

setEmojiQuery = (query) ->

  if query
    { SET_EMOJI_QUERY } = actionTypes
    dispatch SET_EMOJI_QUERY, { query }
  else
    unsetEmojiQuery()

  unsetSelectedEmoji()


unsetEmojiQuery = ->

  { UNSET_EMOJI_QUERY } = actionTypes
  dispatch UNSET_EMOJI_QUERY

  unsetSelectedEmoji()


selectEmoji = (index) ->

  { SET_SELECTED_EMOJI_INDEX } = actionTypes
  dispatch SET_SELECTED_EMOJI_INDEX, { index }


moveToNextEmoji = ->

  { MOVE_TO_NEXT_EMOJI_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_EMOJI_INDEX


moveToPrevEmoji = ->

  { MOVE_TO_PREV_EMOJI_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_EMOJI_INDEX


confirmSelectedEmoji = ->

  { CONFIRM_SELECTED_EMOJI_INDEX } = actionTypes
  dispatch CONFIRM_SELECTED_EMOJI_INDEX


unsetSelectedEmoji = ->

  { UNSET_SELECTED_EMOJI_INDEX } = actionTypes
  dispatch UNSET_SELECTED_EMOJI_INDEX


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setEmojiQuery
  unsetEmojiQuery
  selectEmoji
  moveToNextEmoji
  moveToPrevEmoji
  confirmSelectedEmoji
  unsetSelectedEmoji
}
