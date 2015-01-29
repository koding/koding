class RealtimeController extends KDController

  constructor: (options = {}, data) ->

    # when we remove broker completely, we no longer need to
    # make another caching here
    @channels = {}

    # this is used for discarding events that are received multiple times
    @eventCache = {}

    @localStorage  = KD.getSingleton("localStorageController").storage "realtime"

    # each forbidden channel name is stored in local storage
    # this is used for preventing datadog
    unless @localStorage.getValue 'ForbiddenChannels'
      @localStorage.setValue 'ForbiddenChannels', {}

    super options, data

    {subscribekey, ssl} = KD.config.pubnub

    if KD.isPubnubEnabled()
      @pubnub = PUBNUB.init
        subscribe_key : subscribekey
        uuid          : KD.whoami()._id
        ssl           : ssl

      realtimeToken = Cookies.get("realtimeToken")

      @pubnub.auth realtimeToken  if realtimeToken?


  # channel authentication is needed for notification channel and
  # private channels
  authenticate: (options, callback) ->

    return callback null  unless options?

    { endPoint, data } = options
    return callback { message : "endPoint is not set"}  unless endPoint

    KD.utils.doXhrRequest {endPoint, data}, (err) =>

      return callback err  if err

      # when we make an authentication request, server responses with realtimeToken
      # in cookie here. If it is not set, then there is no need to subscription attempt
      # to pubnub
      realtimeToken = Cookies.get("realtimeToken")

      return callback { message : 'Could not find realtime token'}  unless realtimeToken

      @pubnub.auth realtimeToken

      callback null


  # subscriptionData =
  #   serviceType: 'socialapi'
  #   group      : group.slug
  #   channelType: typeConstant
  #   channelName: name
  #   isExclusive: yes
  #   connectDirectly: yes
  #   brokerChannelName: channelName
  subscribeChannel: (subscriptionData, callback) ->

    # validate first
    { channelName, channelType: typeConstant, group, token } = subscriptionData

    return callback { message: 'channel name is not defined' }  unless channelName

    return @subscribeBroker subscriptionData, callback  unless KD.isPubnubEnabled()

    pubnubChannelName = "channel-#{token}"

    options = { channelName: pubnubChannelName }

    # authentication needed for private message channels (pinnedactivity is for future use )
    if typeConstant in ['privatemessage', 'pinnedactivity']
      options.authenticate =
        endPoint : "/api/gatekeeper/subscribe/channel"
        data     : { name: channelName, typeConstant, groupName: group }

    return @subscribePubnub options, callback


  # unsubscribeChannel unsubscribes the user from given channel
  unsubscribeChannel: (channel) ->

    return @unsubscribeBroker channel  unless KD.isPubnubEnabled()

    @unsubscribePubnub channel


  unsubscribeBroker: (channel) ->
    {groupName, typeConstant, name} = channel
    channelName = "socialapi.#{groupName}-#{typeConstant}-#{name}"
    # unsubscribe from the channel.
    # When a user leaves, and then rejoins a private channel, broker sends
    # related channel from cache, but this channel contains old secret name.
    # For this reason I have added this unsubscribe call.
    # !!! This cache invalidation must be handled when cycleChannel event is received
    KD.remote.mq.unsubscribe channelName


  unsubscribePubnub: (channel) ->

    return  unless channel

    {token} = channel
    channelName = "channel-#{token}"
    @pubnub.unsubscribe({
      channel : channelName,
    })

    delete @channels[channelName]


  # subcribeMessage subscribes to message channels for instance update events
  # message channels do not need any authentication
  subscribeMessage: (message, callback) ->

    return callback null, message  unless KD.isPubnubEnabled()

    {token} = message

    channelName = "instance-#{token}"
    options = { channelName }

    return @subscribePubnub options, callback


  subscribeNotification: (callback) ->
    unless KD.isPubnubEnabled()
      notificationChannel = KD.remote.subscribe 'notification',
        serviceType : 'notification'
        isExclusive : yes

      return callback null, notificationChannel

    { nickname } = KD.whoami().profile
    { environment } = KD.config
    channelName = "notification-#{environment}-#{nickname}"
    options = { channelName }
    options.authenticate =
      endPoint : "/api/gatekeeper/subscribe/notification"
      data     : { id: KD.whoami().socialApiId }

    @subscribePubnub options, callback


  subscribePubnub: (options = {}, callback) ->

    pubnubChannelName = options.channelName

    # return channel if it already exists
    return callback null, @channels[pubnubChannelName]  if @channels[pubnubChannelName]

    @authenticate options.authenticate, (err) =>

      return callback err  if err

      channelInstance = new PubnubChannel name: pubnubChannelName

      @pubnub.subscribe
        channel : pubnubChannelName
        message : (message, env, channel) =>

          return  unless message

          {eventName, body, eventId} = message

          return  if @eventCache[eventId]

          @eventCache[eventId] = yes

          # when a user is connected in two browsers, and leaves a channel, in second one
          # they receive RemovedFromChannel event for their own. Therefore we must unsubscribe
          # user from all connected devices.
          if eventName is 'RemovedFromChannel' and body.accountId is KD.whoami().socialApiId
            return @unsubscribePubnub message.channel

          # no need to emit any events when not subscribed
          return  unless @channels[channel]

          @channels[channel].emit eventName, body
        connect : =>
          @channels[pubnubChannelName] = channelInstance
          callback null, channelInstance
        error   : (err) =>
          @handleError err
          callback err
        # with each channel subscription pubnub resubscribes to every channel
        # and some messages are dropped in this resubscription time interval
        # for this reason for every subscribe request, we are fetching all messages sent
        # in last 3 seconds
        timetoken: ((new Date()).getTime() - 3000) * 10000
        restore : yes


  handleError: (err) ->
    {message, payload} = err

    return warn err  unless payload

    {channels} = payload

    forbiddenChannels = @localStorage.getValue 'ForbiddenChannels'

    for channel in channels
      # if somehow we are not able to subscribe to a channel (public access is not granted etc.)
      # unsubscribe from that channel. Otherwise user will not be able to receive
      # further realtime events
      @pubnub.unsubscribe {channel}
      unless forbiddenChannels[channel]
        channelToken = channel.replace "channel-", ""
        forbiddenChannels[channel] = yes
        @localStorage.setValue 'ForbiddenChannels', forbiddenChannels
        KD.utils.sendDataDogEvent "ForbiddenChannel", tags: {channelToken}, sendLogs: no


  # subscribeBroker subscribes the broker channels when it is enabled.
  # This will be deleted later on
  subscribeBroker: (subscriptionData = {}, callback) ->
    {brokerChannelName:channelName} = subscriptionData
    # do not use callbacks while subscribing, KD.remote.subscribe already
    # returns the required channel object. Use it. Callbacks are called
    # twice in the subscribe function
    realtimeChannel = KD.remote.subscribe channelName, subscriptionData

    callback null, realtimeChannel


class PubnubChannel extends KDObject

  constructor: (options = {}) ->

    super options

    @name = options.name
