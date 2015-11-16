kd                       = require 'kd'
PrivateMessageThreadPane = require 'activity/components/privatemessagethreadpane'
ActivityFlux             = require 'activity/flux'
getGroup                 = require 'app/util/getGroup'
changeToChannel          = require 'activity/util/changeToChannel'

{
  thread  : threadActions,
  channel : channelActions,
  message : messageActions } = ActivityFlux.actions

{ selectedChannelThread, channelByName } = ActivityFlux.getters

NewPrivateChannelRoute = require './newprivatechannel'
AllPrivateChannelsRoute = require './allprivatechannels'
SingleMessageRoute = require './singlemessage'


module.exports = class SinglePrivateChannelRoute

  constructor: ->

    @path = ':privateChannelId'
    @childRoutes = [
      new NewPrivateChannelRoute
      new AllPrivateChannelsRoute
      new SingleMessageRoute
    ]


  getComponents: (state, callback) ->

    callback null,
      content: PrivateMessageThreadPane
      modal: null


  onEnter: (nextState, replaceState, done) ->

    { privateChannelId, postId } = nextState.params

    selectedThread = kd.singletons.reactor.evaluate selectedChannelThread

    # if there is no channel id set on the route (/Messages, /NewMessage)
    unless privateChannelId
      # if there is not a selected chat
      unless selectedThread
        botChannel = kd.singletons.socialapi.getPrefetchedData 'bot'
        # set channel id to bot channel id.
        privateChannelId = botChannel.id

    if privateChannelId
      transitionToChannel privateChannelId, done
    else if not selectedThread
      threadActions.changeSelectedThread null
      done()
    else
      done()


  onLeave: ->

    threadActions.changeSelectedThread null
    messageActions.changeSelectedMessage null


transitionToChannel = (channelId, done) ->

  successFn = ({ channel }) ->
    threadActions.changeSelectedThread channel.id
    channelActions.loadParticipants channel.id
    done()

  channel = kd.singletons.reactor.evaluateToJS ['ChannelsStore', channelId]

  if channel
    successFn { channel }
    messageActions.loadMessages channel.id
  else
    channelActions.loadChannel(channelId).then successFn


