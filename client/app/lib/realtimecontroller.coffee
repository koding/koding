kookies = require 'kookies'
globals = require 'globals'
doXhrRequest = require './util/doXhrRequest'
sendDataDogEvent = require './util/sendDataDogEvent'
whoami = require './util/whoami'
kd = require 'kd'
backoff = require 'backoff'
PubnubChannel = require './pubnubchannel'

require 'pubnub'

NodeNotificationClient = require './nodenotificationclient'


module.exports = class RealtimeController extends kd.Controller

  constructor: (options = {}, data) ->

    super options, data

    # when we remove broker completely, we no longer need to
    # make another caching here
    @channels = {}

    # this is used for discarding events that are received multiple times
    @eventCache = {}
    @initLocalStorage()

    if @isPubNubEnabled()
      @initPubNub()
    else
      @initNodeNotification()


  initLocalStorage: ->

    @localStorage = kd.singletons.localStorageController.storage 'realtime'

    # each forbidden channel name is stored in local storage
    # this is used for preventing datadog
    unless @localStorage.getValue 'ForbiddenChannels'
      @localStorage.setValue 'ForbiddenChannels', {}


  isPubNubEnabled: ->

    { pubnub } = globals.config
    return pubnub.enabled and pubnub.subscribekey


  initPubNub: ->

    { environment, pubnub: { subscribekey, ssl } } = globals.config

    options =
      subscribe_key : subscribekey
      uuid          : whoami()._id
      ssl           : if environment is 'dev' then window.location.protocol is 'https:' else ssl
      noleave       : yes

    @pubnub = PUBNUB.init options

    # when we send a new message, a user receives both the message itself and notification message
    # consecutively, which sometimes causes one of these messages to be dropped.
    # until we learn a better solution, we have seperated notification channel for a new pubnub connection
    # https://www.pivotaltracker.com/story/show/88210800
    @pbNotification = PUBNUB.init options

    fetchServerTime = (callback = kd.noop) =>

      @pubnub.time (timestamp) =>
        return callback Date.now() * 10000  unless timestamp

        @serverTimestamp = timestamp
        @emit 'Ping', timestamp
        callback timestamp

    # syncServerTime
    fetchServerTime (timestamp) =>
      @lastSeenOnline = timestamp

    kd.utils.repeat 10000, fetchServerTime


    # initAuthentication for PubNub
    @authenticated = false

    realtimeToken = kookies.get('realtimeToken')

    if realtimeToken?
      @setPubNubAuthToken realtimeToken
      @authenticated = yes

      return

    # in case of realtime token does not exist, fetch it from Gatekeeper
    options = { endPoint : '/api/gatekeeper/token', data: { id: whoami().socialApiId } }
    @authenticateWithPubNub options, (err) =>

      return kd.warn err  if err

      @authenticated = yes
      @emit 'authenticated'


  setPubNubAuthToken: (token) ->

    @pubnub.auth token
    @pbNotification.auth token


  # channel authentication is needed for notification channel and
  # private channels
  authenticateWithPubNub: (options, callback) ->

    return callback null  unless options?

    { endPoint, data } = options
    return callback { message : 'endPoint is not set' }  unless endPoint

    bo = backoff.exponential
      initialDelay: 700
      maxDelay    : 15000

    bo.on 'fail', -> callback { message: 'Authentication failed.' }
    bo.failAfter 15

    bo.on 'ready', -> bo.backoff()

    requestFn = =>
      doXhrRequest { endPoint, data }, (err) =>
        if err
          return callback { message: "Channel authentication failed: #{err.message}" }

        # when we make an authentication request, server responses with realtimeToken
        # in cookie here. If it is not set, then there is no need to subscription attempt
        # to pubnub
        realtimeToken = kookies.get('realtimeToken')

        return callback { message : 'Could not find realtime token' }  unless realtimeToken

        @setPubNubAuthToken realtimeToken

        bo.reset()

        callback null

    bo.on 'backoff', requestFn

    bo.backoff()


  # subscriptionData =
  #   group      : group.slug
  #   channelType: typeConstant
  #   channelName: name
  subscribeChannel: (subscriptionData, callback) ->

    # validate first
    { channelName, channelType: typeConstant, group, token, channelId } = subscriptionData

    return callback { message: 'channel name is not defined' }  unless channelName

    pubnubChannelName = "channel-#{token}"

    options = { channelName: pubnubChannelName, channelId }

    # authentication needed for private message channels
    if group isnt 'koding' or typeConstant in ['privatemessage', 'collaboration', 'bot']
      options.authenticate =
        endPoint : '/api/gatekeeper/subscribe/channel'
        data     : { name: channelName, typeConstant, groupName: group }

    options.pbInstance = @pubnub

    return @subscribePubNub options, callback


  # unsubscribeChannel unsubscribes the user from given channel
  unsubscribeChannel: (channel) ->

    return  unless channel

    { token } = channel
    channelName = "channel-#{token}"
    @pubnub.unsubscribe({
      channel : channelName,
    })

    delete @channels[channelName]


  # subcribeMessage subscribes to message channels for instance update events
  # message channels do not need any authentication
  subscribeMessage: (message, callback) ->

    { token } = message

    channelName = "instance-#{token}"

    return callback null, @channels[channelName]  if @channels[channelName]

    # just create a channel for instance event reception
    channelInstance = new PubnubChannel { name: channelName }

    @channels[channelName] = channelInstance

    return callback null, channelInstance


  subscribeNotification: (callback) ->

    { nickname } = whoami().profile

    if @isPubNubEnabled()

      { environment } = globals.config
      channelName = "notification-#{environment}-#{nickname}"
      options = { channelName }
      options.authenticate =
        endPoint : '/api/gatekeeper/subscribe/notification'
        data     : { id: whoami().socialApiId }

      options.pbInstance = @pbNotification

      @subscribePubNub options, callback

    else

      callback null, @nodeNotificationClient



  subscribePubNub: (options = {}, callback) ->

    return @subscribeHelper options, callback  if @authenticated

    @once 'authenticated', => @subscribeHelper options, callback


  subscribeHelper: (options = {}, callback) ->
    { channelName: pubnubChannelName, channelId } = options

    # return channel if it already exists
    return callback null, @channels[pubnubChannelName]  if @channels[pubnubChannelName]

    @authenticateWithPubNub options.authenticate, (err) =>

      return callback err  if err

      channelInstance = new PubnubChannel { name: pubnubChannelName, channelId: channelId }

      callbackCalled = no

      pb = options.pbInstance or @pubnub

      pb.subscribe
        channel : pubnubChannelName
        message : (message, env, channel) => @handlePubNubMessage message, channel
        connect : =>
          @channels[pubnubChannelName] = channelInstance
          @removeFromForbiddenChannels pubnubChannelName
          callbackCalled = yes
          callback null, channelInstance
        error   : (err) =>
          @handlePubNubError err
          callback err  unless callbackCalled
        reconnect: (channel) => @reconnectToPubNubChannel channel, pb
        # with each channel subscription pubnub resubscribes to every channel
        # and some messages are dropped in this resubscription time interval
        # for this reason for every subscribe request, we are fetching all messages sent
        # in last 3 seconds
        timetoken: @serverTimestamp - 30000000
        restore : yes

      return callback err  if err


  isPubNubDisconnected: (err) ->
    # I know this is so error prone, but they are not sending any error code; just message. :(
    return err?.message is 'Offline. Please check your network settings.'


  reconnectToPubNubChannel: (channel, pbInstance) ->

    kd.TimeAgoView.emit 'OneMinutePassed'

    @once 'Ping', (serverTimestamp) =>

      return  unless @lastSeenOnline

      # if user is not online for more than a day, then reload the page
      if @lastSeenOnline < serverTimestamp - 864000000000
        return window.location.reload()

      @fetchChannelHistoryFromPubNub {
        channel, timestamp: @lastSeenOnline, pbInstance
      }


  fetchChannelHistoryFromPubNub: (options) ->

    { channel, timestamp, pbInstance } = options

    return  unless timestamp

    pb = pbInstance or @pubnub

    bo = backoff.exponential
      initialDelay: 700
      maxDelay    : 15000

    bo.on 'fail', -> kd.error "Fetch history failed for channel #{channel}"
    bo.failAfter 15

    bo.on 'ready', -> bo.backoff()

    limit = 100
    historyOptions =
      channel : channel
      start   : "#{timestamp}"
      count   : limit
      reverse : true
      callback: (response) =>

        bo.reset()

        return  unless response?.length and Array.isArray(response)

        [messages, start, end] = response

        return  unless messages?.length and Array.isArray(messages)

        @handlePubNubMessage message, channel  for message in messages

        # since the maximum message limit is 100, we are making a recursive call here
        if messages.length is limit
          historyOptions.start = end
          @fetchChannelHistoryFromPubNub { channel, timestamp: end }
      err: (err) -> kd.warn "Could not fetch history #{err.message}"  unless err

    bo.on 'backoff', -> pb.history historyOptions

    bo.backoff()


  handlePubNubMessage: (message, channel) ->

    return  unless message

    { eventName, body, eventId } = message

    return  unless eventName and body

    if eventId?
      return  if @eventCache[eventId]

      @eventCache[eventId] = yes

    # no need to emit any events when not subscribed
    return  unless @channels[channel]

    # instance events are received via public channel. For this reason
    # if an event name includes "instance-", update the related message channel
    # An instance event format is like "instance-5dc4ce55-b159-11e4-8329-c485b673ee34.ReplyAdded" - ctf

    if eventName.indexOf('instance-') < 0
      body.channelId = @channels[channel].channelId
      return @channels[channel].emit eventName, body

    events = eventName.split '.'
    if events.length < 2
      warn 'could not parse event name', eventName
      return

    [instanceChannel, eventName] = events

    return  unless @channels[instanceChannel]

    @channels[instanceChannel].emit eventName, body

    # when a user is connected in two browsers, and leaves a channel, in second one
    # they receive RemovedFromChannel event for their own. Therefore we must unsubscribe
    # user from all connected devices.
    if eventName is 'RemovedFromChannel' and body.accountId is whoami().socialApiId
      return @unsubscribeChannel message.channel


  handlePubNubError: (err) ->

    return  unless err

    { message, payload } = err

    if @isPubNubDisconnected err
      @lastSeenOnline = @serverTimestamp

    return kd.warn err  unless payload?.channels

    { channels } = payload

    forbiddenChannels = @localStorage.getValue 'ForbiddenChannels'

    for channel in channels
      # if somehow we are not able to subscribe to a channel (public access is not granted etc.)
      # unsubscribe from that channel. Otherwise user will not be able to receive
      # further realtime events
      @pubnub.unsubscribe { channel }
      unless forbiddenChannels[channel]
        channelToken = channel.replace 'channel-', ''
        forbiddenChannels[channel] = yes
        @localStorage.setValue 'ForbiddenChannels', forbiddenChannels
        sendDataDogEvent 'ForbiddenChannel', { tags: { channelToken }, sendLogs: no }


  removeFromForbiddenChannels: (channelName) ->

    forbiddenChannels = @localStorage.getValue 'ForbiddenChannels'

    return  unless forbiddenChannels[channelName]

    delete forbiddenChannels[channelName]

    @localStorage.setValue 'ForbiddenChannels', forbiddenChannels


  initNodeNotification: ->

    @nodeNotificationClient = new NodeNotificationClient
    @nodeNotificationClient.connect()
