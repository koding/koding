kd                = require 'kd'
ActivityFlux      = require 'activity/flux'
{ channelByName } = ActivityFlux.getters
{
  thread  : threadActions,
  channel : channelActions } = ActivityFlux.actions

module.exports = transitionToChannel =  (channelName, done) ->

  { reactor } = kd.singletons

  isChannelOpened = no

  channel = channelByName channelName

  if channel
    isChannelOpened = reactor.evaluate ['OpenedChannelsStore', channel.id]

  # if we have an opened channel, switch to it immediately.
  if isChannelOpened
    threadActions.changeSelectedThread channel.id
    done null, channel
  else
    channelActions.loadChannelByName(channelName).then ({channel}) ->
      threadActions.changeSelectedThread channel.id
      channelActions.loadParticipants channel.id
      done null, channel
