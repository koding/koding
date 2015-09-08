kd                     = require 'kd'
actionTypes            = require './actiontypes'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Sets last message edit mode
 *
 * @param {string} accountId
###
setLastMessageEditMode = (accountId) ->

  { SET_LAST_MESSAGE_EDIT_MODE } = actionTypes
  dispatch SET_LAST_MESSAGE_EDIT_MODE, { accountId }


module.exports = {
  setLastMessageEditMode
}

