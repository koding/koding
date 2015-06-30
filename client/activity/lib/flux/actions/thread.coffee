kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

###*
 * Change selected thread's id to given channel id.
 *
 * @param {string} channelId
###
changeSelectedThread = (channelId) ->

  { CHANGE_SELECTED_THREAD } = actionTypes

  dispatch CHANGE_SELECTED_THREAD, { channelId }


dispatch = (args...) -> kd.singletons.reactor args...


module.exports = {
  changeSelectedThread
}
