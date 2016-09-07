actions                        = require '../actions/actiontypes'
immutable                      = require 'immutable'
toImmutable                    = require 'app/util/toImmutable'
KodingFluxStore                = require 'app/flux/base/store'
getDefaultNotificationSettings = require 'activity/util/getDefaultNotificationSettings'

###*
 * Store to handle channel notification settings
###
module.exports = class ChannelNotificationSettingsStore extends KodingFluxStore

  @getterPath = 'ChannelNotificationSettingsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_GLOBAL_NOTIFICATION_SETTINGS_SUCCESS,    @setSettings
    @on actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_FAIL,      @handleLoadFail
    @on actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS,   @setSettings
    @on actions.UPDATE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, @setSettings
    @on actions.DELETE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, @deleteSettings
    @on actions.CREATE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, @createSettings


  setSettings: (notificationSettings, { channelId, channelNotificationSettings }) ->

    _oldSettings    = notificationSettings.get channelNotificationSettings.channelId
    defaultSettings = if _oldSettings then _oldSettings.toJS() else getDefaultNotificationSettings()

    for key of channelNotificationSettings
      if channelNotificationSettings[key] is null
        channelNotificationSettings[key] = defaultSettings[key]

    notificationSettings.set channelId, toImmutable channelNotificationSettings


  handleLoadFail: (notificationSettings, { channelId, groupChannelId }) ->

    defaultSettings = notificationSettings.get groupChannelId

    return notificationSettings  unless defaultSettings

    newSettings = defaultSettings.set '_newlyCreated', yes

    notificationSettings.set channelId, newSettings


  deleteSettings: (notificationSettings, { channelId }) ->

    notificationSettings = notificationSettings.remove channelId


  createSettings: (notificationSettings, options) ->

    channelId = options.channelId
    delete options.channelId

    notificationSettings = notificationSettings.set channelId, toImmutable options
