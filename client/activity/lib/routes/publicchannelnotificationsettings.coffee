kd                        = require 'kd'
ActivityFlux              = require 'activity/flux'
NotificationSettingsModal = require 'activity/components/publicchannelnotificationsettingsmodal'
NotificationSettingsFlux  = require 'activity/flux/channelnotificationSettings'

{ selectedChannelThread, channelByName } = ActivityFlux.getters


module.exports = class PublicChannelNotificationSettingsRoute

  constructor: ->

    @path = '/Channels/:channelName/NotificationSettings'


  getComponent: (state, callback) -> callback null, NotificationSettingsModal


  onEnter: (nextState, replaceState, done) ->

    { channelName } = nextState.params

    channel   = channelByName channelName
    channelId = channel.id

    NotificationSettingsFlux.actions.channel.load channelId
      .then -> done()

