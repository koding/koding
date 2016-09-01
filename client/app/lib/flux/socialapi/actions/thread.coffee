kd           = require 'kd'
actionTypes  = require '../actions/actiontypes'
getGroup     = require 'app/util/getGroup'
getters      = require '../getters'

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



openChannel = (channel) ->

  { router } = kd.singletons
  if channel.typeConstant in [ 'privatemessage', 'bot' ]
  then router.handleRoute "/Messages/#{channel.id}"
  else router.handleRoute "/Channels/#{channel.name}"

getNavigationDeps = ->

  { reactor }      = kd.singletons
  selectedId       = reactor.evaluate getters.selectedChannelThreadId
  followedChannels = reactor.evaluateToJS getters.allFollowedChannels
  followedIds      = Object.keys followedChannels

  return { selectedId, followedChannels, followedIds }


###*
 * Open previous followed channel.
###
openPrev = ->

  { selectedId, followedChannels, followedIds } = getNavigationDeps()
  selectedIndex = followedIds.indexOf selectedId

  prevId = if (index = selectedIndex - 1) >= 0
  then followedIds[index]
  else followedIds.last

  openChannel followedChannels[prevId]


###*
 * Open next followed channel.
###
openNext = ->

  { selectedId, followedChannels, followedIds } = getNavigationDeps()
  selectedIndex = followedIds.indexOf selectedId

  nextId = if (index = selectedIndex + 1) < followedIds.length
  then followedIds[index]
  else followedIds.first

  openChannel followedChannels[nextId]



###*
 * Open previous followed channel which has unread items.
###
openUnreadPrev = ->

  { selectedId, followedChannels, followedIds } = getNavigationDeps()
  followedIds = followedIds.filter (id) ->
    channel = followedChannels[id]
    return channel.unreadCount

  return  unless followedIds.length

  selectedIndex = followedIds.indexOf selectedId

  prevId = if (index = selectedIndex - 1) >= 0
  then followedIds[index]
  else followedIds.last

  openChannel followedChannels[prevId]


###*
 * Open next followed channel which has unread items.
###
openUnreadNext = ->

  { selectedId, followedChannels, followedIds } = getNavigationDeps()
  followedIds = followedIds.filter (id) ->
    channel = followedChannels[id]
    return channel.unreadCount

  return  unless followedIds.length

  selectedIndex = followedIds.indexOf selectedId

  nextId = if (index = selectedIndex + 1) < followedIds.length
  then followedIds[index]
  else followedIds.first

  openChannel followedChannels[nextId]


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  changeSelectedThread
  changeSelectedThreadByName
  openPrev
  openNext
  openUnreadPrev
  openUnreadNext
}
