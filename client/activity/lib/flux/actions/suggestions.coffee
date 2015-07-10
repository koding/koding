kd          = require 'kd'
actionTypes = require '../actions/actiontypes'


changeCurrentQuery = (query) ->

  { SET_CURRENT_SUGGESTION_QUERY } = actionTypes

  dispatch SET_CURRENT_SUGGESTION_QUERY, { query }


changeAccess = (isAccessible) ->

  { CHANGE_SUGGESTION_ACCESS } = actionTypes
  dispatch CHANGE_SUGGESTION_ACCESS, { isAccessible }


changeVisibility = (isHidden) ->

  { CHANGE_SUGGESTION_VISIBILITY } = actionTypes
  dispatch CHANGE_SUGGESTION_VISIBILITY, { isHidden }


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  changeCurrentQuery
  changeAccess
  changeVisibility
}
