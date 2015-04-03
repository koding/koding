kd = require 'kd'
getNick = require 'app/util/nick'
BaseChatVideoView = require 'app/videocollaboration/views/baseview'

module.exports = class IDEChatVideoView extends BaseChatVideoView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'ChatVideo--IDEChatVideo', options.cssClass

    super options, data


  ###*
   * Take a type and return a handler.
   *
   * TODO: probably need to improve this api.
   *
   * @see {@link BaseChatVideoView::handleStateChanged} for more info.
  ###
  handleStateChangeRequest: (type) -> (active) ->

    kd.singletons.appManager.tell 'IDE', 'toggleVideoControl', type, active


