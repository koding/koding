kd          = require 'kd'
isKoding    = require 'app/util/isKoding'
actionTypes = require '../actions/actiontypes'

###*
 * Change selected thread's id to given channel id.
 *
 * @param {string} channelId
###
changeSelectedThread = (channelId) ->

  { SET_SELECTED_CHANNEL_THREAD } = actionTypes

  dispatch SET_SELECTED_CHANNEL_THREAD, { channelId }


###*
 * Change selected thread's id by given channel slug.
 *
 * @param {string} name - slug of the channel
###
changeSelectedThreadByName = (name) ->

  { SET_SELECTED_CHANNEL_THREAD_FAIL,
    SET_SELECTED_CHANNEL_THREAD } = actionTypes

  type = if isKoding()
    switch name
      when 'Public'    then 'group'
      when 'Changelog' then 'announcement'
      else 'topic'
  else 'topic'

  name = name.toLowerCase()

  kd.singletons.socialapi.channel.byName { name, type }, (err, channel) ->
    if err
      dispatch SET_SELECTED_CHANNEL_THREAD_FAIL, { err }
      return

    dispatch SET_SELECTED_CHANNEL_THREAD, { channelId: channel.id }


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  changeSelectedThread
  changeSelectedThreadByName
}
