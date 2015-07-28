kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

setQuery = (query) ->

  { SET_EMOJI_QUERY } = actionTypes

  dispatch SET_EMOJI_QUERY, { query }
  selectEmoji ''


selectEmoji = (emoji) ->

  { SET_SELECTED_EMOJI } = actionTypes

  dispatch SET_SELECTED_EMOJI, { emoji }


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setQuery
  selectEmoji
}
