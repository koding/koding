kd = require 'kd'
getNick = require 'app/util/nick'
BaseChatVideoView = require 'app/videocollaboration/views/baseview'

module.exports = class IDEChatVideoView extends BaseChatVideoView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'ChatVideo--IDEChatVideo', options.cssClass

    super options, data


