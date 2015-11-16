kd                        = require 'kd'
ActivityFlux              = require 'activity/flux'
NotificationSettingsModal = require 'activity/components/publicchannelnotificationsettingsmodal'
NotificationSettingsFlux  = require 'activity/flux/channelnotificationsettings'

{ selectedChannelThread, channelByName } = ActivityFlux.getters


module.exports = class PublicChannelNotificationSettingsRoute

  constructor: ->

    @path = 'NotificationSettings'


  getComponent: (state, callback) -> callback null, NotificationSettingsModal


  onEnter: (nextState, replaceState, done) ->

    channel = channelByName nextState.params.channelName

    NotificationSettingsFlux.actions.channel.load(channel.id).then -> done()

