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
    @timeDiff = 0

    @authenticated = false

    if KD.isPubnubEnabled()
      @pubnub = PUBNUB.init
        subscribe_key : subscribekey
        uuid          : KD.whoami()._id
        ssl           : if KD.config.environment is 'dev' then window.location.protocol is 'https:' else ssl

      realtimeToken = Cookies.get("realtimeToken")

      @fetchServerTime()
      setInterval =>
        @fetchServerTime()
      , 10000

      if realtimeToken?
        @pubnub.auth realtimeToken
        @authenticated = yes

        return

      # in case of realtime token does not exist, fetch it from Gatekeeper
      options = { endPoint : "/api/gatekeeper/token", data: { id: KD.whoami().socialApiId } }
      @authenticate options, (err) =>

        return warn err  if err

        @authenticated = yes
        @emit 'authenticated'


  fetchServerTime: ->
    @pubnub.time (timestamp) =>
      return  unless timestamp

      @serverTimestamp = timestamp
      @emit 'Ping', timestamp


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

    return callback null, @channels[channelName]  if @channels[channelName]

    # just create a channel for instance event reception
    channelInstance = new PubnubChannel name: channelName

    @channels[channelName] = channelInstance

    return callback null, channelInstance


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

    return @subscribeHelper options, callback  if @authenticated

    @once 'authenticated', => @subscribeHelper options, callback


  subscribeHelper: (options = {}, callback) ->
    pubnubChannelName = options.channelName

    # return channel if it already exists
    return callback null, @channels[pubnubChannelName]  if @channels[pubnubChannelName]

    @authenticate options.authenticate, (err) =>

      return callback err  if err

      channelInstance = new PubnubChannel name: pubnubChannelName

      callbackCalled = no
      @pubnub.subscribe
        channel : pubnubChannelName
        message : (message, env, channel) => @handleMessage message, channel
        connect : =>
          @channels[pubnubChannelName] = channelInstance
          @removeFromForbiddenChannels pubnubChannelName
          callbackCalled = yes
          callback null, channelInstance
        error   : (err) =>
          @handleError err
          callback err  unless callbackCalled
        reconnect: (channel) => @reconnect channel

        # with each channel subscription pubnub resubscribes to every channel
        # and some messages are dropped in this resubscription time interval
        # for this reason for every subscribe request, we are fetching all messages sent
        # in last 3 seconds
        timetoken: @serverTimestamp - 30000000
        restore : yes


  isDisconnected: (err) ->
    # I know this is so error prone, but they are not sending any error code; just message. :(
    return err?.message is 'Offline. Please check your network settings.'


  reconnect: (channel) ->
    @once 'Ping', (serverTimestamp) =>

      return  unless @lastSeenOnline

      # if user is not online for more than a day, then reload the page
      if @lastSeenOnline < serverTimestamp - 864000000000
        return window.location.reload()

      @fetchHistory channel, @lastSeenOnline
      @lastSeenOnline = null


  fetchHistory: (channel, timestamp) ->

    return  unless timestamp

    limit = 100
    @pubnub.history
      channel : channel
      start   : "#{timestamp}"
      count   : limit
      reverse : true
      callback: (response) =>

        return  unless response?.length and Array.isArray(response)

        messages = response[0]
        start    = response[1]

        return  unless messages?.length and Array.isArray(messages)

        @handleMessage message, channel  for message in messages

        # since the maximum message limit is 100, we are making a recursive call here
        @fetchHistory channel, start  if messages.length is limit
      err: (err) ->
        # instead of getting into a stale state, just reload the page
        window.location.reload()  if err


  handleMessage: (message, channel) ->

    return  unless message

    {eventName, body, eventId} = message

    return  unless eventName and body

    if eventId?
      return  if @eventCache[eventId]

      # TODO delete this periodically
      @eventCache[eventId] = yes


    # when a user is connected in two browsers, and leaves a channel, in second one
    # they receive RemovedFromChannel event for their own. Therefore we must unsubscribe
    # user from all connected devices.
    if eventName is 'RemovedFromChannel' and body.accountId is KD.whoami().socialApiId
      return @unsubscribePubnub message.channel

    # no need to emit any events when not subscribed
    return  unless @channels[channel]

    # instance events are received via public channel. For this reason
    # if an event name includes "instance-", update the related message channel
    # An instance event format is like "instance-5dc4ce55-b159-11e4-8329-c485b673ee34.ReplyAdded"
    if eventName.indexOf("instance-") < 0
      return @channels[channel].emit eventName, body

    events = eventName.split "."
    if events.length < 2
      warn 'could not parse event name', eventName
      return

    instanceChannel = events[0]
    eventName = events[1]

    return  unless @channels[instanceChannel]

    @channels[instanceChannel].emit eventName, body


  handleError: (err) ->
    {message, payload} = err

    if @isDisconnected err
      @lastSeenOnline = @serverTimestamp

    return warn err  unless payload?.channels

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


  removeFromForbiddenChannels: (channelName) ->
    forbiddenChannels = @localStorage.getValue 'ForbiddenChannels'

    return  unless forbiddenChannels[channelName]

    delete forbiddenChannels[channelName]

    @localStorage.setValue 'ForbiddenChannels', forbiddenChannels


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
