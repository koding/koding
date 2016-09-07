ActivityFlux              = require 'activity/flux'
NotificationSettingsModal = require 'activity/components/publicchannelnotificationsettingsmodal'
NotificationSettingsFlux  = require 'activity/flux/channelnotificationsettings'

module.exports = class PublicChannelNotificationSettingsRoute

  constructor: ->

    @path = 'NotificationSettings'


  getComponent: (state, callback) -> callback null, NotificationSettingsModal


  onEnter: (nextState, replaceState, done) ->

    { channelByName } = ActivityFlux.getters

    channel = channelByName nextState.params.channelName

    NotificationSettingsFlux.actions.channel.load(channel.id).then -> done()
