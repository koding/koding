kd = require 'kd'
ChannelThreadPane    = require 'activity/components/channelthreadpane'
ActivityFlux = require 'activity/flux'
getGroup             = require 'app/util/getGroup'

renderWithBackgroundChannel = (Component, callback) ->

  { getters, actions } = ActivityFlux
  { reactor }          = kd.singletons

  selectedThread = reactor.evaluate getters.selectedChannelThread

  # if there is no selected thread, meaning that a user is reloading in this
  # route load the group channel first and then render the modal, so that the
  # background of the modal will have a content.
  unless selectedThread
    actions.channel.loadChannelByName(getGroup().slug).then ({ channel }) ->
      actions.thread.changeSelectedThread channel.id
      actions.channel.loadParticipants channel.id
      callback null,
        content: ChannelThreadPane
        modal: Component

  else
    callback null,
      content: null
      modal: Component


module.exports = {
  renderWithBackgroundChannel
}

