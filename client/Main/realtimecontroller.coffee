class RealtimeController extends KDController

  constructor: (options = {}, data) ->

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

    that = this
    @pubnub.subscribe
      channel : prepareChannelName options
      message : (message, env, channel) =>
        if message
          {eventName, body} = message
          that.emit eventName, body

  prepareChannelName = (options) ->
    { channelName, typeConstant, group, token } = options

    return "#{token}-#{group}-#{typeConstant}-#{channelName}"
