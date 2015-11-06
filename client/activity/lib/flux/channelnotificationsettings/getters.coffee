immutable                  = require 'immutable'
ActivityFluxGetters        = require 'activity/flux/getters'
getGroup                   = require 'app/util/getGroup'

withEmptyMap  = (storeData) -> storeData or immutable.Map()


selectedChannelThreadId           = [['SelectedChannelThreadIdStore'], withEmptyMap]
channelNotificationSettingsStore  = ['ChannelNotificationSettingsStore']

globalNotificationSettings = [
  channelNotificationSettingsStore
  (settings) -> settings.get getGroup().socialApiChannelId
]

channelNotificationSettings = [
  channelNotificationSettingsStore
  ActivityFluxGetters.selectedChannelThreadId
  (settings, id) ->
    settings.get id
]


module.exports = {
  globalNotificationSettings
  channelNotificationSettings
}

