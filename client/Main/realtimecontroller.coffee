class RealtimeController extends KDController

  constructor: (options = {}, data) ->

    # when we remove broker completely, we no longer need to
    # make another caching here
    @channels = {}

    super options, data

    {subscribekey} = KD.config.pubnub

    @pubnub = PUBNUB.init subscribe_key : subscribekey

  # subscriptionData =
  #   serviceType: 'socialapi'
  #   group      : group.slug
  #   channelType: socialApiChannel.typeConstant
  #   channelName: socialApiChannel.name
  authenticate: (options = {}, callback = noop) ->

    { channelName, typeConstant, group } = options
    return callback { message: "channel name is not defined" }  unless channelName

    endPoint = '/api/gatekeeper/channel/authenticate'
    data = {name: channelName, typeConstant, group}
    KD.utils.doXhrRequest {endPoint, data}, callback

  subscribe: (options = {}) ->
    { channelName, typeConstant, group } = options
    return KD.showError { message: "channel name is not set" }  unless channelName

    pubnubChannelName = prepareChannelName options

    # return channel if it already exists
    return @channels[pubnubChannelName]  if @channels[pubnubChannelName]

    channelInstance = new PubnubChannel()
    @channels[pubnubChannelName] = channelInstance

    @pubnub.subscribe
      channel : pubnubChannelName
      message : (message, env, channel) =>
        return  unless message
        {eventName, body} = message

        # no need to emit any events when not subscribed
        return  unless @channels[channel]

        @channels[channel].emit eventName, body

    return channelInstance

  prepareChannelName = (options) ->
    { channelName, typeConstant, group, token } = options

    return "#{token}-#{group}-#{typeConstant}-#{channelName}"


class PubnubChannel extends KDObject

  constructor: (options = {}) ->

    super options
