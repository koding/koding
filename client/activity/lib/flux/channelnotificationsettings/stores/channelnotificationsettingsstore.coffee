actions                        = require '../actions/actiontypes'
immutable                      = require 'immutable'
toImmutable                    = require 'app/util/toImmutable'
KodingFluxStore                = require 'app/flux/base/store'

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

    notificationSettings.set channelId, toImmutable channelNotificationSettings


  handleLoadFail: (notificationSettings, { channelId, groupChannelId }) ->

    channelNotificationSettings = notificationSettings.get groupChannelId
    channelNotificationSettings = channelNotificationSettings.set '_newlyCreated', yes

    notificationSettings.set channelId, channelNotificationSettings


  deleteSettings: (notificationSettings, { channelId }) ->

    notificationSettings = notificationSettings.remove channelId


  createSettings: (notificationSettings, options) ->

    channelId = options.channelId
    delete options.channelId

    notificationSettings = notificationSettings.set channelId, toImmutable options


