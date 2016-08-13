kd                       = require 'kd'
_                        = require 'lodash'
AppFlux                  = require 'app/flux'
whoami                   = require 'app/util/whoami'
fetchAccount             = require 'app/util/fetchAccount'
fetchAccounts            = require 'app/util/fetchAccounts'
NotificationSettingsFlux = require 'activity/flux/channelnotificationsettings'

{ user: userActions } = AppFlux.actions

unreadCount             = 0
channels                = []
messages                = []
accounts                = []
resetMessagesTimer      = null
continuosMessagingTimer = null


# if user receive any message or messages, we post web notification to user
# by message count, message senders and the frequency of receiving message.
postMessageReceivedNotification = (message, channel) ->

  return  if kd.singletons.windowController.isFocused()

  callback = ->

    clearTimeout continuosMessagingTimer  if continuosMessagingTimer and messages.length > 1

    messages.push message
    channels.push channel
    accounts.push { id : message.account._id, constructorName: 'JAccount' }

    if messages.length > 1
      clearTimeout resetMessagesTimer  if resetMessagesTimer

      # if user post messages as continuosly we are waiting for 4000ms then post
      # notification. If user post a message again in this time, we cancel the
      # last notification and wait another 4000ms then post notification.
      continuosMessagingTimer = setTimeout ->
        postNotificationForReceivedMessage channel, messages, accounts
      , 4000
    else
      postNotificationForReceivedMessage channel, messages, accounts

  return callback()  if message.typeConstant is 'privatemessage'

  fetchNotificationSettingsAndPostNotification message.initialChannelId, (settings) ->

    return  if settings.get 'isMuted'
    return callback()  if settings.get('desktopSetting') is 'all'


postNotificationForReceivedMessage = (channel, messages, accounts) ->

  route = if channel.typeConstant in ['privatemessage', 'collaboration']
  then "/Messages/#{channel.id}"
  else "/Channels/#{channel.name}"

  if messages.length and messages.length > 1
    channels      = _.uniq channels, 'id'
    accounts      = _.uniq accounts, 'id'
    unreadCount  += channel.unreadCount  for channel in channels
    title         = "You have #{unreadCount} messages"
    notification  =  { title, message: '', route }

    fetchAccounts accounts, (err, accounts) ->
      notification.message = _prepareBody(accounts)
      kd.singletons.desktopNotifications.notify(notification)
      _reset()
  else
    userActions.loadAccount(messages[0].account._id).then ({ account }) ->
      title   = "New message from #{account.profile.nickname}"
      message = _sliceLongText messages[0].body

      kd.singletons.desktopNotifications.notify { title, message, route }

      # we have to wait for reset messages. if we don't, it posts a
      # notification for each message without waiting continuous messaging
      # we post first message and wait a while, if any message received in this time
      # we post another notification to show user how many unread message he has.
      # To good ux, we avoided to show lots of notifications on the screen for each message.
      resetMessagesTimer = setTimeout ->
        _reset()
      , 4000

_reset = ->
  unreadCount = 0
  channels    = []
  messages    = []
  accounts    = []

_prepareBody = (accounts) ->
  body = 'from '
  len  = accounts.length
  [0...len].forEach (i) ->
    body += accounts[i].profile.nickname
    if i + 2 is len
      body += ' and '
    else if i + 1 is len
      body += ''
    else
      body += ', '

  return _sliceLongText body

_sliceLongText = (text) ->
  text = text.replace(/(\r\n|\n|\r)/gm, ' ').trim()
  text = if text.length > 30 then "#{text.slice 0, 30}..." else text
  return text


postMentionedNotification = (options) ->

  return  if kd.singletons.windowController.isFocused()

  ActivityFlux = require 'activity/flux'

  { message: messageActions, channel: channelActions } = ActivityFlux.actions

  messageBody = channelName = sender = null

  postNotification = ->

    return  unless messageBody and channelName and sender

    title   = "New message in ##{channelName}"
    message = _sliceLongText "#{sender}: #{messageBody}"
    route   = "/Channels/#{channelName}/#{options.targetId}"

    kd.singletons.desktopNotifications.notify { title, message, route }

    messageBody = channelName = sender = null


  postNotificationBySettings = (channelSettings, channelId) ->

    { desktopSetting, isMuted, isSuppressed } = channelSettings.toJS()

    isMention = messageBody.indexOf("@#{whoami().profile.nickname}") > -1

    return  if isMuted
    return  if not isMention and isSuppressed
    return  if isMention and desktopSetting is 'never'

    channelActions.loadChannel(channelId).then ({ channel }) ->
      channelName = channel.name
      postNotification()

  account = { id: options.actorId, constructorName: 'JAccount' }

  fetchAccount account, (err, account) ->
    sender = "#{account.profile.nickname}"
    postNotification()

  messageActions.loadMessage(options.targetId).then ({ message }) ->

    return  if message.typeConstant is 'privatemessage'

    messageBody = message.body
    channelId   = message.initialChannelId

    fetchNotificationSettingsAndPostNotification channelId, postNotificationBySettings


postAddedToChannelNotification = (channelName, addedBy, typeConstant) ->

  return  if kd.singletons.windowController.isFocused()
  return  if addedBy is whoami().profile.nickname

  channelName = if typeConstant is 'privatemessage' then 'a private' else "##{channelName}"
  title   = _sliceLongText "Added to #{channelName} channel as participant"
  message = _sliceLongText "#{addedBy} added you to #{channelName} channel as a participant"
  route   = "/Channels/#{channelName}"

  kd.singletons.desktopNotifications.notify { title, message, route }


fetchNotificationSettingsAndPostNotification = (channelId, callback) ->

  { reactor } = kd.singletons
  { channelNotificationSettings } = NotificationSettingsFlux.getters

  allSettings     = reactor.evaluate ['ChannelNotificationSettingsStore']
  channelSettings = allSettings.get channelId

  return callback channelSettings, channelId  if channelSettings

  NotificationSettingsFlux.actions.channel.load(channelId).then ({ settings }) ->
    allSettings = reactor.evaluate ['ChannelNotificationSettingsStore']
    channelSettings = allSettings.get channelId
    callback channelSettings, channelId


module.exports = {
  postMentionedNotification
  postMessageReceivedNotification
  postAddedToChannelNotification
}


