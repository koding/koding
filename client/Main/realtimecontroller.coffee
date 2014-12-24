class RealtimeController extends KDController

  constructor: (options = {}, data) ->

    # when we remove broker completely, we no longer need to
    # make another caching here
    @channels = {}

    super options, data

    {subscribekey} = KD.config.pubnub

    @pubnub = PUBNUB.init subscribe_key : subscribekey
  # channel authentication is needed for notification channel and
  # private channels
  authenticate: (options, callback) ->

    return callback null  unless options?

    { endPoint, data } = options
    return callback { message : "endPoint is not set"}  unless endPoint

    KD.utils.doXhrRequest {endPoint, data}, callback


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
  # subcribeMessage subscribes to message channels for instance update events
  # message channels do not need any authentication
  subscribeMessage: (message, callback) ->

    return callback null, message  unless KD.isPubnubEnabled()

    {token} = message

    channelName = "instance-#{token}"
    options = { channelName }

    return @subscribePubnub options, callback


  subscribePubnub: (options = {}, callback) ->

    pubnubChannelName = options.channelName

    # return channel if it already exists
    return callback null, @channels[pubnubChannelName]  if @channels[pubnubChannelName]

    @authenticate options.authenticate, (err) =>

      return callback err  if err

      realtimeToken = Cookies.get("realtimeToken")
      @pubnub.auth realtimeToken

      channelInstance = new PubnubChannel name: pubnubChannelName

      @pubnub.subscribe
        channel : pubnubChannelName
        message : (message, env, channel) =>
          return  unless message
          {eventName, body} = message

          # no need to emit any events when not subscribed
          return  unless @channels[channel]

          @channels[channel].emit eventName, body
        connect : =>
          @channels[pubnubChannelName] = channelInstance
          callback null, channelInstance
        error   : (err) -> callback err # not sure if it is really sending an error
        restore : yes


class PubnubChannel extends KDObject

  constructor: (options = {}) ->

    super options

    @name = options.name
