kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

changeCurrentQuery = (query) ->

  { SET_CURRENT_SUGGESTION_QUERY } = actionTypes

  dispatch SET_CURRENT_SUGGESTION_QUERY, { query }


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  changeCurrentQuery
}
