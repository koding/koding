kd          = require 'kd'
isKoding    = require 'app/util/isKoding'
actionTypes = require '../actions/actiontypes'
getGroup    = require 'app/util/getGroup'

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

  name = name.toLowerCase()

  type = switch name
    when 'public'                     then 'group'
    when 'changelog', getGroup().slug then 'announcement'
    else 'topic'

  kd.singletons.socialapi.channel.byName { name, type }, (err, channel) ->
    if err
      dispatch SET_SELECTED_CHANNEL_THREAD_FAIL, { err }
      return

    dispatch SET_SELECTED_CHANNEL_THREAD, { channelId: channel.id }


switchToDefaultChannelForStackRequest = ->

  getGroup().fetchAdmins (err, admins) ->

    { slug, socialApiDefaultChannelId } = getGroup()

    kd.singletons.router.handleRoute "/Channels/#{slug}"

    nicknames = admins.map (a) -> "@#{a.profile.nickname}"
    suffix = if nicknames.length > 1 then 's' else ''
    inputValue = """
      Hi #{suffix} #{nicknames.join ' '}, I don't have my VMs. Can you please create a stack?
    """

    ChatInputFlux = require 'activity/flux/chatinput'
    ChatInputFlux.actions.value.setValue socialApiDefaultChannelId, inputValue


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  changeSelectedThread
  changeSelectedThreadByName
  switchToDefaultChannelForStackRequest
}
