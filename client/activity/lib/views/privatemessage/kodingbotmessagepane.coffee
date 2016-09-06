fetchChannelMessages = require 'activity/util/fetchChannelMessages'
PrivateMessagePane   = require './privatemessagepane'
kd = require 'kd'


module.exports = class KodingBotMessagePane extends PrivateMessagePane

  constructor: (options = {}) ->

    botChannel = kd.singletons.socialapi.getPrefetchedData 'bot'
    options.cssClass = kd.utils.curry 'privatemessage', options.cssClass

    super options, botChannel

    @listController.getListView().setClass 'kdlistview-privatemessage'
    @actionsMenu?.destroy()
    @participantHeads?.newParticipantButton?.destroy()

  fetch: (options = {}, callback) ->

    { name, type, channelId } = @getOptions()

    fetchChannelMessages {name, type, id: channelId} , (err, data) =>

      channel = @getData()
      channel.replies = data
      callback err, data
