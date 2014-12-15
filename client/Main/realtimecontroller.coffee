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
    KD.utils.doXhrRequest {endPoint, data, async: no}, callback

  subscribe: (options = {}, callback = noop) ->

    pubnubChannelName = prepareChannelName options

    # return channel if it already exists
    return @channels[pubnubChannelName]  if @channels[pubnubChannelName]

    channelInstance = new PubnubChannel name: pubnubChannelName
    @channels[pubnubChannelName] = channelInstance

    @pubnub.subscribe
      channel : pubnubChannelName
      message : (message, env, channel) =>
        return  unless message
        {eventName, body} = message

        # no need to emit any events when not subscribed
        return  unless @channels[channel]

        @channels[channel].emit eventName, body
      connect : -> callback null
      error   : (err) -> callback err # not sure if it is really sending an error
      restore : yes

    return channelInstance

  prepareChannelName = (options) ->
    { eventType } = options
    switch eventType
      when 'channel'
        { channelName, typeConstant, group, token } = options
        return "channel-#{token}-#{group}-#{typeConstant}-#{channelName}"
      when 'instance'
        { token } = options
        return "instance-#{token}"
      when 'notification'
        {nickname} = options
        {environment} = KD.config
        return "notification-#{environment}-#{nickname}"

    return ""


class PubnubChannel extends KDObject

  constructor: (options = {}) ->

    super options

    @name = options.name
