ActivityFluxGetters        = require 'activity/flux/getters'

channelNotificationSettingsStore  = ['ChannelNotificationSettingsStore']

channelNotificationSettings = [
  channelNotificationSettingsStore
  ActivityFluxGetters.selectedChannelThreadId
  (settings, id) ->
    settings.get id
]


module.exports = {
  channelNotificationSettings
}
