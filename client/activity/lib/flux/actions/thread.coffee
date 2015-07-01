kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

###*
 * Change selected thread's id to given channel id.
 *
 * @param {string} channelId
###
changeSelectedThread = (channelId) ->

  { SET_SELECTED_CHANNEL_THREAD } = actionTypes

  dispatch SET_SELECTED_CHANNEL_THREAD, { channelId }


dispatch = (args...) -> kd.singletons.reactor args...


module.exports = {
  changeSelectedThread
}
