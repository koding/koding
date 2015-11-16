kd                             = require 'kd'
actionTypes                    = require './actiontypes'
getGroup                       = require 'app/util/getGroup'
getDefaultNotificationSettings = require 'activity/util/getDefaultNotificationSettings'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

loadGlobal = ->

  channelId = getGroup().socialApiChannelId

  { LOAD_GLOBAL_NOTIFICATION_SETTINGS_FAIL
    LOAD_GLOBAL_NOTIFICATION_SETTINGS_SUCCESS } = actionTypes

  { socialapi } = kd.singletons

  socialapi.notificationSetting.fetch { channelId }, (err, channelNotificationSettings) ->
    if err
      dispatch LOAD_GLOBAL_NOTIFICATION_SETTINGS_FAIL, { err, channelId }

      globalNotificationSettings           = getDefaultNotificationSettings()
      globalNotificationSettings.channelId = channelId

      return createSettings globalNotificationSettings

    dispatch LOAD_GLOBAL_NOTIFICATION_SETTINGS_SUCCESS, { channelId, channelNotificationSettings }


load = (channelId) ->

  groupChannelId = getGroup().socialApiChannelId

  { LOAD_CHANNEL_NOTIFICATION_SETTINGS_FAIL
    LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS } = actionTypes

  new Promise (resolve, reject) ->

    { socialapi } = kd.singletons

    socialapi.notificationSetting.fetch { channelId }, (err, channelNotificationSettings) ->
      if err
        dispatch LOAD_CHANNEL_NOTIFICATION_SETTINGS_FAIL, { err, channelId, groupChannelId }
        resolve { channelId }
        return

      dispatch LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId, channelNotificationSettings }

      resolve { channelId }


updateSettings = (channelId, channelNotificationSettings) ->

  groupChannelId = getGroup().socialApiChannelId

  { UPDATE_CHANNEL_NOTIFICATION_SETTINGS_FAIL
    UPDATE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS } = actionTypes

  { socialapi } = kd.singletons

  new Promise (resolve, reject) ->

    socialapi.notificationSetting.update channelNotificationSettings, (err, channelNotificationSettings) ->
      if err
        dispatch UPDATE_CHANNEL_NOTIFICATION_SETTINGS_FAIL, { err, channelId, channelNotificationSettings }
        return

      dispatch UPDATE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId, channelNotificationSettings }

      resolve { channelId }


deleteSettings = (channelId, settingsId) ->

  groupChannelId = getGroup().socialApiChannelId

  { DELETE_CHANNEL_NOTIFICATION_SETTINGS_FAIL
    DELETE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS } = actionTypes

  { socialapi } = kd.singletons

  new Promise (resolve, reject) ->


    socialapi.notificationSetting.delete { id: settingsId }, (err, notificationSettings) ->
      if err
        dispatch DELETE_CHANNEL_NOTIFICATION_SETTINGS_FAIL, { err, channelId }
        return

      dispatch DELETE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId }

      resolve { channelId }


createSettings = (options) ->

  { CREATE_CHANNEL_NOTIFICATION_SETTINGS_FAIL
    CREATE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS } = actionTypes

  { socialapi } = kd.singletons

  new Promise (resolve, reject) ->

    socialapi.notificationSetting.create options, (err, options) ->
      if err
        dispatch CREATE_CHANNEL_NOTIFICATION_SETTINGS_FAIL, { err, options }
        return

      dispatch CREATE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, options

      resolve options


redirectToChannel: (channelName) ->


  route = "/Channels/#{channelName}"

  kd.singletons.router.handleRoute route


saveSettings = (options) ->

  { channelId, channelName, channelSettings } = options
  globalSettings  = getDefaultNotificationSettings()
  isEqual         = yes
  isNewlyCreated  = channelSettings._newlyCreated

  for item of globalSettings
    if globalSettings[item] != channelSettings[item]
      isEqual = no
      break

  route = "/Channels/#{channelName}"

  if isEqual and isNewlyCreated
    return kd.singletons.router.handleRoute route

  if isEqual and not isNewlyCreated
    deleteSettings channelId, channelSettings.id
      .then ->
        kd.singletons.router.handleRoute route
  else if !isNewlyCreated
    updateSettings channelId, channelSettings
      .then ->
        kd.singletons.router.handleRoute route
  else
    channelSettings.channelId = channelId
    createSettings channelSettings
      .then ->
        kd.singletons.router.handleRoute route


module.exports = {
  load
  loadGlobal
  createSettings
  updateSettings
  deleteSettings
  saveSettings
}

